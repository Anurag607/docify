import 'package:docify/services/form_entry.dart';
import '../services/database_service.dart';

class SuggestionService {
  static final DatabaseService _dbService = DatabaseService();

  // Get suggestions for a specific field
  static Future<List<String>> getSuggestions(
      String templateId, String fieldLabel,
      {int limit = 5}) async {
    return _dbService.getSuggestions(templateId, fieldLabel, limit: limit);
  }

  // Save form entry data
  static Future<void> saveFormEntry(
      String templateId, Map<String, String> fieldValues) async {
    final entry = FormEntry(
      templateId: templateId,
      fieldValues: fieldValues,
    );

    await _dbService.saveFormEntry(entry);
  }
}
