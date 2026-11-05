import 'package:flutter_test/flutter_test.dart';
import 'package:healingpianta/core/josa.dart';

void main() {
  group('hasBatchim', () {
    test('한글 받침', () {
      expect(hasBatchim('새싹'), isTrue);
      expect(hasBatchim('무순'), isTrue);
      expect(hasBatchim('초록'), isTrue);
      expect(hasBatchim('콩나물'), isTrue);
      expect(hasBatchim('보리'), isFalse);
      expect(hasBatchim('다채'), isFalse);
      expect(hasBatchim('가'), isFalse);
      expect(hasBatchim('힣'), isTrue);
    });

    test('끝의 공백·문장부호·이모지는 건너뜀', () {
      expect(hasBatchim('새싹 '), isTrue);
      expect(hasBatchim('보리!'), isFalse);
      expect(hasBatchim('새싹🌱'), isTrue);
      expect(hasBatchim('(초록)'), isTrue);
      expect(hasBatchim("'보리'"), isFalse);
    });

    test('숫자는 읽는 소리 기준', () {
      expect(hasBatchim('1'), isTrue); // 일
      expect(hasBatchim('2'), isFalse); // 이
      expect(hasBatchim('3'), isTrue); // 삼
      expect(hasBatchim('4'), isFalse); // 사
      expect(hasBatchim('5'), isFalse); // 오
      expect(hasBatchim('6'), isTrue); // 육
      expect(hasBatchim('7'), isTrue); // 칠
      expect(hasBatchim('8'), isTrue); // 팔
      expect(hasBatchim('9'), isFalse); // 구
      expect(hasBatchim('0'), isTrue); // 영
      expect(hasBatchim('10'), isTrue); // 십
      expect(hasBatchim('100'), isTrue); // 백
      expect(hasBatchim('1000'), isTrue); // 천
      expect(hasBatchim('새싹2'), isFalse); // 새싹이
      expect(hasBatchim('3호'), isFalse); // 마지막 글자 '호'
    });

    test('영문 이름 근사', () {
      expect(hasBatchim('Tom'), isTrue); // 톰
      expect(hasBatchim('Bill'), isTrue); // 빌
      expect(hasBatchim('Ann'), isTrue); // 앤
      expect(hasBatchim('King'), isTrue); // 킹
      expect(hasBatchim('Rock'), isTrue); // 록
      expect(hasBatchim('Jane'), isTrue); // 제인
      expect(hasBatchim('Lime'), isTrue); // 라임
      expect(hasBatchim('Book'), isTrue); // 북
      expect(hasBatchim('Cat'), isTrue); // 캣
      expect(hasBatchim('Mia'), isFalse); // 미아
      expect(hasBatchim('Leo'), isFalse); // 레오
      expect(hasBatchim('Star'), isFalse); // 스타
      expect(hasBatchim('Bus'), isFalse); // 버스
      expect(hasBatchim('Dog'), isFalse); // 도그
      expect(hasBatchim('Kate'), isFalse); // 케이트
      expect(hasBatchim('sprout'), isTrue); // 스프라웃
    });

    test('대문자 약어는 알파벳 이름으로', () {
      expect(hasBatchim('ABC'), isFalse); // 에이비시
      expect(hasBatchim('SNS'), isFalse); // 에스엔에스
      expect(hasBatchim('BTM'), isTrue); // 비티엠
      expect(hasBatchim('KL'), isTrue); // 케이엘
      expect(hasBatchim('N'), isTrue); // 엔
      expect(hasBatchim('A'), isFalse); // 에이
    });

    test('판단할 수 없으면 null', () {
      expect(hasBatchim(''), isNull);
      expect(hasBatchim('🌱'), isNull);
      expect(hasBatchim('!!'), isNull);
      expect(hasBatchim('さくら'), isNull);
      expect(hasBatchim('木'), isNull);
    });
  });

  group('attachJosa', () {
    test('이/가', () {
      expect(attachJosa('새싹', Josa.iGa), '새싹이');
      expect(attachJosa('보리', Josa.iGa), '보리가');
    });
    test('은/는', () {
      expect(attachJosa('새싹', Josa.eunNeun), '새싹은');
      expect(attachJosa('보리', Josa.eunNeun), '보리는');
    });
    test('을/를', () {
      expect(attachJosa('새싹', Josa.eulReul), '새싹을');
      expect(attachJosa('보리', Josa.eulReul), '보리를');
    });
    test('와/과', () {
      expect(attachJosa('새싹', Josa.waGwa), '새싹과');
      expect(attachJosa('보리', Josa.waGwa), '보리와');
    });
    test('아/야', () {
      expect(attachJosa('새싹', Josa.aYa), '새싹아');
      expect(attachJosa('보리', Josa.aYa), '보리야');
    });
    test('이랑/랑', () {
      expect(attachJosa('새싹', Josa.irang), '새싹이랑');
      expect(attachJosa('보리', Josa.irang), '보리랑');
    });
    test('영문·숫자', () {
      expect(attachJosa('Tom', Josa.iGa), 'Tom이');
      expect(attachJosa('Mia', Josa.iGa), 'Mia가');
      expect(attachJosa('7', Josa.eunNeun), '7은');
      expect(attachJosa('2', Josa.eunNeun), '2는');
    });
    test('모를 때는 두 형태를 함께', () {
      expect(attachJosa('🌱', Josa.iGa), '🌱이(가)');
      expect(attachJosa('🌱', Josa.waGwa), '🌱과(와)');
      expect(attachJosa('🌱', Josa.irang), '🌱(이)랑');
    });
  });

  group('fillTemplate', () {
    test('조사 슬롯 치환', () {
      expect(
        fillTemplate('{name.이가} 우리 집에 왔어요. {name.와과} 함께해요.', {'name': '새싹'}),
        '새싹이 우리 집에 왔어요. 새싹과 함께해요.',
      );
      expect(
        fillTemplate('{name.이가} 우리 집에 왔어요. {name.와과} 함께해요.', {'name': '보리'}),
        '보리가 우리 집에 왔어요. 보리와 함께해요.',
      );
    });

    test('조사 없는 슬롯과 여러 슬롯', () {
      expect(
        fillTemplate('{name.은는} {day}일째, {care_days}번 돌봤어요.', {
          'name': '초록',
          'day': '4',
          'care_days': '3',
        }),
        '초록은 4일째, 3번 돌봤어요.',
      );
    });

    test('다른 슬롯도 같은 조사 문법을 씀', () {
      expect(
        fillTemplate('지난번 {action.을를} 한 날', {'action': '물 한 컵 마시기'}),
        '지난번 물 한 컵 마시기를 한 날',
      );
      expect(fillTemplate('{action.을를}', {'action': '세수'}), '세수를');
      expect(fillTemplate('{action.을를}', {'action': '산책'}), '산책을');
    });

    test('값이 없는 슬롯이 있으면 null', () {
      expect(fillTemplate('{name.이가} {day}일째', {'name': '새싹'}), isNull);
      expect(fillTemplate('{name}', {'name': ''}), isNull);
      expect(fillTemplate('{name.없는조사}', {'name': '새싹'}), isNull);
    });

    test('슬롯이 없는 문구는 그대로', () {
      expect(fillTemplate('좋은 아침이에요.', const {}), '좋은 아침이에요.');
    });
  });

  test('slotsIn / unsupportedJosaIn', () {
    expect(slotsIn('{name.이가} {day} {name}'), ['name', 'day']);
    expect(unsupportedJosaIn('{name.이가} {name.의}'), ['의']);
  });
}
