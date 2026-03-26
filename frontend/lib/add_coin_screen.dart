import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';
import 'ai_detector_service.dart';

class AddCoinScreen extends StatefulWidget {
  final String? imagePath; //Optional captured image path

  const AddCoinScreen({super.key, this.imagePath});

  @override
  State<AddCoinScreen> createState() => _AddCoinScreenState();
}

class _AddCoinScreenState extends State<AddCoinScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _yearController = TextEditingController();
  final _valueController = TextEditingController();

  final AiDetectorService _aiService = AiDetectorService();
  bool _isAnalyzing = false;
  List<DetectionResult> _aiResults = [];

  bool _isSaving = false;

  //1.Trigger AI analysis on screen load if image exists
  @override
  void initState() {
    super.initState();
    if (widget.imagePath != null) {
      _startAiAnalysis();
    }
  }

  //2.Execute AI analysis process
  Future<void> _startAiAnalysis() async {
    setState(() => _isAnalyzing = true);

    await _aiService.initialize();
    final results = await _aiService.analyzeCoin(widget.imagePath!);

    if (mounted) {
      setState(() {
        _aiResults = results;
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _saveCoin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final String newId = const Uuid().v4();
      String? permanentImagePath;

      if (widget.imagePath != null) {
        final String currentPath = widget.imagePath!;
        final File tempImage = File(currentPath);
        final Directory appDir = await getApplicationDocumentsDirectory();

        final String fileName = '${newId}_${path.basename(currentPath)}';
        permanentImagePath = path.join(appDir.path, fileName);

        await tempImage.copy(permanentImagePath);
        debugPrint("PIC SAVED AT: $permanentImagePath");
      }

      // Parses the AI detection results into a single formatted string
      String aiFindings = _aiResults.map((e) => e.label).join(" | ");

      final newCoin = {
        "id": newId,
        "name": _nameController.text,
        "country": _countryController.text,
        "year": int.parse(_yearController.text),
        "faceValue": double.parse(_valueController.text.replaceAll(',', '.')),
        "imagePath": permanentImagePath,
        "anomalies": aiFindings.isNotEmpty ? aiFindings : null,
        "isSynced": 0,
      };

      await DatabaseHelper.instance.insertCoin(newCoin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coin saved at local vault!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _yearController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Coin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              //Display captured image preview
              if (widget.imagePath != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(widget.imagePath!),
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              //Display AI analysis state and results
              if (_isAnalyzing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text("AI is analyzing anomalies and mint marks...",
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    ],
                  ),
                )
              else if (_aiResults.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      border: Border.all(color: Colors.amber.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.amber),
                            SizedBox(width: 8),
                            Text("AI Discoveries", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const Divider(),
                        ..._aiResults.map((result) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(result.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                              ),
                              Text("${(result.confidence * 100).toInt()}% match",
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Coin Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? 'Please enter a name' : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? 'Please enter a country' : null,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _valueController,
                      decoration: const InputDecoration(
                        labelText: 'Value (€)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveCoin,
                  icon: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Coin',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}