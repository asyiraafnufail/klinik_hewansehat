import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/local_file_viewmodel.dart';

class LocalFileViewerView extends StatefulWidget {
  final String filePath;
  const LocalFileViewerView({super.key, required this.filePath});

  @override
  State<LocalFileViewerView> createState() => _LocalFileViewerViewState();
}

class _LocalFileViewerViewState extends State<LocalFileViewerView> {
  String? _content;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final vm = context.read<LocalFileViewModel>();
    final data = await vm.openFile(widget.filePath);
    if (!mounted) return;
    setState(() {
      _content = data;
      _error = vm.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filename = widget.filePath.split('/').last;
    final padding = AppTheme.pagePadding(context);

    return Scaffold(
      appBar: AppBar(title: Text(filename)),
      body: GlassBackground(
        child: SafeArea(
          child: ResponsiveBody(
            maxWidth: 600,
            child: Builder(
              builder: (context) {
                if (_error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Gagal membaca berkas: $_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                if (_content == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: 16),
                  child: FadeSlideIn(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: AppTheme.glassBoxDecoration(radius: 22),
                      child: SelectableText(
                        _content!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
