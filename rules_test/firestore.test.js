// Firestore 보안 규칙 테스트 — 에뮬레이터에서 실행 (npm run emulator)
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

const PROJECT_ID = 'demo-healingpianta';
let env;

const alice = () => env.authenticatedContext('alice').firestore();
const bob = () => env.authenticatedContext('bob').firestore();
const guest = () => env.unauthenticatedContext().firestore();

/** 규칙을 거치지 않고 데이터를 넣는다 (서버/Admin 역할). */
async function seed(path, data) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

describe('users/{uid}', () => {
  test('본인 문서는 만들고 읽을 수 있다', async () => {
    await assertSucceeds(setDoc(doc(alice(), 'users/alice'), { birthYear: 1990, level: 1, careDaysTotal: 0 }));
    await assertSucceeds(getDoc(doc(alice(), 'users/alice')));
  });

  test('타인 문서는 읽기·쓰기·삭제 모두 거부', async () => {
    await seed('users/alice', { birthYear: 1990 });
    await assertFails(getDoc(doc(bob(), 'users/alice')));
    await assertFails(setDoc(doc(bob(), 'users/alice'), { birthYear: 2000 }));
    await assertFails(updateDoc(doc(bob(), 'users/alice'), { level: 2 }));
    await assertFails(deleteDoc(doc(bob(), 'users/alice')));
  });

  test('로그인하지 않으면 거부', async () => {
    await seed('users/alice', { birthYear: 1990 });
    await assertFails(getDoc(doc(guest(), 'users/alice')));
    await assertFails(setDoc(doc(guest(), 'users/guest'), { birthYear: 1990 }));
  });

  test('누적 돌본 날과 레벨은 줄일 수 없다', async () => {
    await seed('users/alice', { careDaysTotal: 10, level: 2 });
    await assertSucceeds(updateDoc(doc(alice(), 'users/alice'), { careDaysTotal: 11 }));
    await assertFails(updateDoc(doc(alice(), 'users/alice'), { careDaysTotal: 3 }));
    await assertFails(updateDoc(doc(alice(), 'users/alice'), { level: 1 }));
    await assertSucceeds(updateDoc(doc(alice(), 'users/alice'), { level: 3 }));
  });

  test('잘못된 출생 연도 거부', async () => {
    await assertFails(setDoc(doc(alice(), 'users/alice'), { birthYear: '1990' }));
    await assertFails(setDoc(doc(alice(), 'users/alice'), { birthYear: 1500 }));
  });
});

describe('plants / photos', () => {
  const photo = 'users/alice/plants/p1/photos/ph1';

  test('본인 식물은 쓰고 읽을 수 있다, 타인은 거부', async () => {
    await assertSucceeds(setDoc(doc(alice(), 'users/alice/plants/p1'), { speciesId: 'radish', name: '새싹' }));
    await assertSucceeds(getDoc(doc(alice(), 'users/alice/plants/p1')));
    await assertFails(getDoc(doc(bob(), 'users/alice/plants/p1')));
    await assertFails(setDoc(doc(bob(), 'users/alice/plants/p2'), { speciesId: 'radish' }));
  });

  test('사진 문서를 pending 으로 만들 수 있다', async () => {
    await assertSucceeds(
      setDoc(doc(alice(), photo), { storagePath: 'x.jpg', dayIndex: 1, analysisStatus: 'pending' }),
    );
  });

  test('클라이언트가 analysis 를 쓰면 거부 (생성)', async () => {
    await assertFails(
      setDoc(doc(alice(), photo), { storagePath: 'x.jpg', analysis: { stage: 'harvest_ready' } }),
    );
    await assertFails(setDoc(doc(alice(), photo), { storagePath: 'x.jpg', displayStage: 'harvest_ready' }));
    await assertFails(setDoc(doc(alice(), photo), { storagePath: 'x.jpg', analysisStatus: 'done' }));
  });

  test('클라이언트가 analysis 를 쓰면 거부 (수정)', async () => {
    await seed(photo, { storagePath: 'x.jpg', analysisStatus: 'pending' });
    await assertFails(updateDoc(doc(alice(), photo), { analysis: { stage: 'overgrown' } }));
    await assertFails(updateDoc(doc(alice(), photo), { displayStage: 'overgrown' }));
    await assertFails(updateDoc(doc(alice(), photo), { analysisStatus: 'done' }));
  });

  test('메모와 기분은 고칠 수 있다', async () => {
    await seed(photo, { storagePath: 'x.jpg', analysisStatus: 'done', analysis: { stage: 'sprout' } });
    await assertSucceeds(updateDoc(doc(alice(), photo), { note: '잘 자라요', moodAtTime: 3 }));
  });

  test('서버가 쓴 analysis 는 본인이 읽을 수 있고 타인은 못 읽는다', async () => {
    await seed(photo, { storagePath: 'x.jpg', analysisStatus: 'done', analysis: { stage: 'sprout' } });
    await assertSucceeds(getDoc(doc(alice(), photo)));
    await assertFails(getDoc(doc(bob(), photo)));
  });
});

describe('기록 컬렉션', () => {
  for (const col of ['checkins/2026-11-05', 'actions/a1', 'messageLog/m1', 'notifLog/n1']) {
    test(`${col.split('/')[0]}: 본인만`, async () => {
      await assertSucceeds(setDoc(doc(alice(), `users/alice/${col}`), { x: 1 }));
      await assertSucceeds(getDoc(doc(alice(), `users/alice/${col}`)));
      await assertFails(getDoc(doc(bob(), `users/alice/${col}`)));
      await assertFails(setDoc(doc(bob(), `users/alice/${col}`), { x: 2 }));
    });
  }

  test('정의되지 않은 하위 컬렉션은 거부', async () => {
    await assertFails(setDoc(doc(alice(), 'users/alice/secrets/s1'), { x: 1 }));
    await assertFails(setDoc(doc(alice(), 'anything/else'), { x: 1 }));
  });
});

describe('usage (서버 전용)', () => {
  test('본인도 쓸 수 없다', async () => {
    await assertFails(setDoc(doc(alice(), 'users/alice/usage/2026-11-05'), { analysisCount: 0 }));
  });

  test('본인은 읽을 수 있고 타인은 못 읽는다', async () => {
    await seed('users/alice/usage/2026-11-05', { analysisCount: 3 });
    await assertSucceeds(getDoc(doc(alice(), 'users/alice/usage/2026-11-05')));
    await assertFails(getDoc(doc(bob(), 'users/alice/usage/2026-11-05')));
    await assertFails(updateDoc(doc(alice(), 'users/alice/usage/2026-11-05'), { analysisCount: 0 }));
  });
});

describe('groups (Phase 15 초안)', () => {
  beforeEach(async () => {
    await seed('groups/g1', { memberUids: ['alice', 'bob'], inviteCode: 'ABC123' });
  });

  test('멤버만 그룹을 읽는다, 클라이언트는 그룹을 만들거나 고칠 수 없다', async () => {
    await assertSucceeds(getDoc(doc(alice(), 'groups/g1')));
    await assertFails(getDoc(doc(env.authenticatedContext('carol').firestore(), 'groups/g1')));
    await assertFails(updateDoc(doc(alice(), 'groups/g1'), { memberUids: ['alice', 'bob', 'carol'] }));
    await assertFails(setDoc(doc(alice(), 'groups/g2'), { memberUids: ['alice'] }));
  });

  test('피드에는 본인 모형 스냅샷만, 사진·텍스트는 거부', async () => {
    const ok = { uid: 'alice', sproutSnapshot: { speciesId: 'radish', stage: 'sprout' }, dayIndex: 3, createdAt: 1 };
    await assertSucceeds(setDoc(doc(alice(), 'groups/g1/feed/f1'), ok));
    await assertFails(setDoc(doc(alice(), 'groups/g1/feed/f2'), { ...ok, uid: 'bob' }));
    await assertFails(setDoc(doc(alice(), 'groups/g1/feed/f3'), { ...ok, photoUrl: 'x' }));
    await assertFails(setDoc(doc(alice(), 'groups/g1/feed/f4'), { ...ok, text: '안녕' }));
  });

  test('반응은 3종만', async () => {
    const r = { fromUid: 'alice', toFeedId: 'f1', type: 'water', createdAt: 1 };
    await assertSucceeds(setDoc(doc(alice(), 'groups/g1/reactions/r1'), r));
    await assertFails(setDoc(doc(alice(), 'groups/g1/reactions/r2'), { ...r, type: 'heart' }));
    await assertFails(setDoc(doc(alice(), 'groups/g1/reactions/r3'), { ...r, comment: 'hi' }));
    await assertFails(
      setDoc(doc(env.authenticatedContext('carol').firestore(), 'groups/g1/reactions/r4'), { ...r, fromUid: 'carol' }),
    );
  });
});
