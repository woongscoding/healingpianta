// Storage 보안 규칙 테스트 — 에뮬레이터에서 실행 (npm run emulator)
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteObject, getBytes, ref, uploadBytes } from 'firebase/storage';

const PROJECT_ID = 'demo-healingpianta';
let env;

const storageOf = (uid) => env.authenticatedContext(uid).storage();
const jpeg = (size = 1024) => new Uint8Array(size);
const asJpeg = { contentType: 'image/jpeg' };

before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    storage: { rules: readFileSync('../storage.rules', 'utf8') },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearStorage();
});

describe('users/{uid}/plants/{plantId}/{photo}', () => {
  const path = 'users/alice/plants/p1/ph1.jpg';

  test('본인 경로에 이미지 업로드·읽기·삭제', async () => {
    const s = storageOf('alice');
    await assertSucceeds(uploadBytes(ref(s, path), jpeg(), asJpeg));
    await assertSucceeds(getBytes(ref(s, path)));
    await assertSucceeds(deleteObject(ref(s, path)));
  });

  test('타인 경로 업로드·읽기 거부', async () => {
    await assertSucceeds(uploadBytes(ref(storageOf('alice'), path), jpeg(), asJpeg));
    await assertFails(uploadBytes(ref(storageOf('bob'), 'users/alice/plants/p1/ph2.jpg'), jpeg(), asJpeg));
    await assertFails(getBytes(ref(storageOf('bob'), path)));
    await assertFails(deleteObject(ref(storageOf('bob'), path)));
  });

  test('로그인하지 않으면 거부', async () => {
    const s = env.unauthenticatedContext().storage();
    await assertFails(uploadBytes(ref(s, path), jpeg(), asJpeg));
  });

  test('이미지가 아니면 거부', async () => {
    await assertFails(uploadBytes(ref(storageOf('alice'), path), jpeg(), { contentType: 'application/pdf' }));
    await assertFails(uploadBytes(ref(storageOf('alice'), path), jpeg(), { contentType: 'text/plain' }));
  });

  test('5MB 까지 허용, 넘으면 거부', async () => {
    const s = storageOf('alice');
    await assertSucceeds(uploadBytes(ref(s, path), jpeg(5 * 1024 * 1024), asJpeg));
    await assertFails(uploadBytes(ref(s, 'users/alice/plants/p1/big.jpg'), jpeg(5 * 1024 * 1024 + 1), asJpeg));
  });

  test('정해진 경로 밖은 거부', async () => {
    const s = storageOf('alice');
    await assertFails(uploadBytes(ref(s, 'users/alice/other.jpg'), jpeg(), asJpeg));
    await assertFails(uploadBytes(ref(s, 'public/x.jpg'), jpeg(), asJpeg));
  });
});
