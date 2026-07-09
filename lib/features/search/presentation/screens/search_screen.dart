import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:walkout/shared/widgets/widgets.dart';

import '../widgets/search_results.dart';
import '../widgets/search_suggestions.dart';

/// Full-text search across fighters and events, pushed on top of the shell
/// so the default [AppBar] back button returns to the previous screen.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  /// Trimmed + lowercased copy used for matching. The controller itself
  /// keeps whatever the user typed, so the raw text is always available for
  /// display via [_controller.text].
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    setState(() => _query = value.trim().toLowerCase());
  }

  void _handleClear() {
    _controller.clear();
    setState(() => _query = '');
  }

  void _handleSuggestionSelected(String name) {
    _controller.text = name;
    _handleChanged(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppSearchBar(
          controller: _controller,
          autofocus: true,
          onChanged: _handleChanged,
          onClear: _query.isEmpty ? null : _handleClear,
        ),
      ),
      body: _query.isEmpty
          ? SearchSuggestions(onSelect: _handleSuggestionSelected)
          : SearchResults(query: _query),
    );
  }
}
