import 'package:flutter/material.dart';
import 'care_unit_storage.dart';

class ApiDataViewScreen extends StatefulWidget {
  const ApiDataViewScreen({Key? key}) : super(key: key);

  @override
  State<ApiDataViewScreen> createState() => _ApiDataViewScreenState();
}

class _ApiDataViewScreenState extends State<ApiDataViewScreen> {
  Map<String, dynamic>? _careUnitData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await CareUnitStorage.loadCareUnitData();
    setState(() {
      _careUnitData = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Data View')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _careUnitData == null
          ? const Center(child: Text('No data found'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Care Unit API Data:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(_careUnitData.toString()),
                  ],
                ),
              ),
            ),
    );
  }
}
