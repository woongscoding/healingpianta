import 'json_reader.dart';
import 'species_content.dart' show duplicateIds;

class Recipe {
  Recipe({
    required this.id,
    required this.title,
    required this.cooked,
    required this.minutes,
    required this.minEnergy,
    required this.ingredients,
    required this.steps,
  });

  factory Recipe.fromJson(JsonReader r) => Recipe(
        id: r.str('id'),
        title: r.str('title'),
        cooked: r.boolean('cooked'),
        minutes: r.integer('minutes'),
        minEnergy: r.integer('minEnergy'),
        ingredients: r.strList('ingredients', allowEmpty: false),
        steps: r.strList('steps', allowEmpty: false),
      );

  final String id;
  final String title;

  /// 익혀 먹는 메뉴. true인 레시피를 먼저 보여준다.
  final bool cooked;
  final int minutes;
  final int minEnergy;
  final List<String> ingredients;
  final List<String> steps;
}

class RecipesContent {
  RecipesContent({required this.safetyTitle, required this.safetySteps, required this.recipes});

  factory RecipesContent.fromJson(Object? json) {
    final r = JsonReader.root('recipes.json', json);
    final safety = r.obj('safety');
    return RecipesContent(
      safetyTitle: safety.str('title'),
      safetySteps: safety.strList('steps', allowEmpty: false),
      recipes: [for (final x in r.objList('recipes')) Recipe.fromJson(x)],
    );
  }

  final String safetyTitle;
  final List<String> safetySteps;
  final List<Recipe> recipes;

  /// 익혀 먹는 메뉴 먼저, 그다음 짧은 시간 순.
  List<Recipe> get ordered => [...recipes]
    ..sort((a, b) {
      if (a.cooked != b.cooked) return a.cooked ? -1 : 1;
      return a.minutes.compareTo(b.minutes);
    });

  List<String> validate() {
    final errors = duplicateIds('recipes.json', recipes.map((r) => r.id));
    for (final x in recipes) {
      if (x.minEnergy < 1 || x.minEnergy > 3) errors.add('recipes.json ${x.id}.minEnergy 는 1~3');
      if (x.minutes <= 0) errors.add('recipes.json ${x.id}.minutes 는 양수');
    }
    if (!recipes.any((x) => x.cooked && x.minEnergy == 1)) {
      errors.add('recipes.json 에 에너지 1로 할 수 있는 익혀 먹는 메뉴가 없음');
    }
    return errors;
  }
}
