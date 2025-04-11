import 'package:flutter/material.dart';
import '../models/template.dart';
import '../models/form_entry.dart';
import '../services/database_service.dart';

class TemplateEntriesScreen extends StatefulWidget {
  final Template template;

  const TemplateEntriesScreen({super.key, required this.template});

  @override
  State<TemplateEntriesScreen> createState() => _TemplateEntriesScreenState();
}

class _TemplateEntriesScreenState extends State<TemplateEntriesScreen> {
  final DatabaseService _dbService = DatabaseService();
  final ScrollController _scrollController = ScrollController();
  final List<FormEntry> _entries = [];
  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newEntries = await _dbService.getAllEntriesForTemplate(
        widget.template.id,
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        _entries.addAll(newEntries);
        _currentPage++;
        _hasMore = newEntries.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading entries: $e')),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadEntries();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.template.name} - Entries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showClearEntriesDialog(),
            tooltip: 'Clear All Entries',
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _entries.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final entry = _entries[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              title: Text('Entry ${index + 1}'),
              subtitle: Text('Created: ${_formatDate(entry.createdAt)}'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entry.fieldValues.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                '${e.key}:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(child: Text(e.value)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showClearEntriesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Entries'),
        content: const Text(
            'This will delete all entries for this template. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.clearTemplateEntries(widget.template.id);
              if (mounted) {
                Navigator.of(context).pop();
                setState(() {
                  _entries.clear();
                  _currentPage = 1;
                  _hasMore = true;
                });
                _loadEntries();
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
