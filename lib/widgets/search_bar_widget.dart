import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final bool isLoading;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.isLoading = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSearch(_controller.text.trim());
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 14),
            child: Icon(Icons.search, color: Color(0xffd4722a), size: 22),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Cari warkop, cafe, nama tempat...',
                hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                setState(() {});
              },
              child: const Padding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 8),
                child: Icon(Icons.close, color: Colors.white38, size: 18),
              ),
            ),
          GestureDetector(
            onTap: widget.isLoading ? null : _submit,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: widget.isLoading ? Colors.grey : const Color(0xffd4722a),
                borderRadius: BorderRadius.circular(10),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Cari',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
