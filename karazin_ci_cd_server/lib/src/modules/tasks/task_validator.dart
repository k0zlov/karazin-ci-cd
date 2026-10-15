class TaskValidator {
  static bool isValidTitle(String? title) {
    if (title == null) {
      return false;
    }

    final trimmed = title.trim();

    return trimmed.isNotEmpty && trimmed.length <= 100;
  }

  static bool isValidDescription(String? description) {
    if (description == null) {
      return true;
    }

    return description.length <= 500;
  }
}
