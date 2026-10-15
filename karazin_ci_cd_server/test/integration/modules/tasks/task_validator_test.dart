import 'package:karazin_ci_cd_server/src/modules/tasks/task_validator.dart';
import 'package:test/test.dart';

void main() {
  group('TaskValidator', () {
    group('isValidTitle', () {
      test('returns true for valid title', () {
        expect(
          TaskValidator.isValidTitle('Learn Serverpod'),
          isTrue,
        );
      });

      test('returns false for null title', () {
        expect(
          TaskValidator.isValidTitle(null),
          isFalse,
        );
      });

      test('returns false for empty title', () {
        expect(
          TaskValidator.isValidTitle(''),
          isFalse,
        );
      });

      test('returns false for whitespace only title', () {
        expect(
          TaskValidator.isValidTitle('   '),
          isFalse,
        );
      });

      test('returns false when title is longer than 100 characters', () {
        final title = 'a' * 101;

        expect(
          TaskValidator.isValidTitle(title),
          isFalse,
        );
      });
    });

    group('isValidDescription', () {
      test('returns true for null description', () {
        expect(
          TaskValidator.isValidDescription(null),
          isTrue,
        );
      });

      test('returns true for valid description', () {
        expect(
          TaskValidator.isValidDescription('Some description'),
          isTrue,
        );
      });

      test('returns false when description is longer than 500 characters', () {
        final description = 'a' * 501;

        expect(
          TaskValidator.isValidDescription(description),
          isFalse,
        );
      });
    });
  });
}