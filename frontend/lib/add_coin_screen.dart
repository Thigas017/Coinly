import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddCoinScreen extends StatefulWidget {
  const AddCoinScreen({super.key});

  @override
  State<AddCoinScreen> createState() => _AddCoinScreenState();
}

class _AddCoinScreenState extends State<AddCoinScreen> {
  //Form key used for input validation before submission
  final _formKey = GlobalKey<FormState>();

  //Controllers used to retrieve user input
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _yearController = TextEditingController();
  final _valueController = TextEditingController();

  bool _isSaving = false;

  Future<void> _saveCoin() async {
    //Validate form fields before submission
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isSaving = true; });

    //Prepare payload for backend submission
    final url = Uri.parse('http://10.0.2.2:8080/api/coins');
    final newCoin = {
      "name": _nameController.text,
      "country": _countryController.text,
      "year": int.parse(_yearController.text),
      "faceValue": double.parse(_valueController.text.replaceAll(',', '.')),
    };

    try {
      //Send POST request with JSON body
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(newCoin),
      );

      //Status 200 (OK) or 201 (Created) indicate success
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          //Close screen and notify previous screen of successful creation
          Navigator.pop(context, true);
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Connection error: Unable to reach server.');
    } finally {
      setState(() { _isSaving = false; });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    //Dispose controllers to prevent memory leaks
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
                      validator: (value) =>
                      value!.isEmpty ? 'Required' : null,
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
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) =>
                      value!.isEmpty ? 'Required' : null,
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
                    backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
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