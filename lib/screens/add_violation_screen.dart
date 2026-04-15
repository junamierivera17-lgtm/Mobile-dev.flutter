import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// ================= MODELS =================

class User {
  final String id;
  final String name;

  User({required this.id, required this.name});
}

enum ViolationType { late, uniform, behavior }

enum ViolationStatus { pending, approved }

class Violation {
  String id;
  String studentId;
  ViolationType type;
  DateTime date;
  String remarks;
  ViolationStatus status;
  int offenseCount;
  String reportedBy;

  Violation({
    required this.id,
    required this.studentId,
    required this.type,
    required this.date,
    required this.remarks,
    required this.status,
    required this.offenseCount,
    required this.reportedBy,
  });
}

/// ================= DATA =================

final List<User> students = [
  User(id: '1', name: 'Jeff'),
  User(id: '2', name: 'Kath'),
  User(id: '3', name: 'Hannah'),
  User(id: '4', name: 'Juna'),
  User(id: '5', name: 'Jas'),
];

List<Violation> violations = [];

/// ================= APP =================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}

/// ================= DASHBOARD =================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String searchText = "";

  String getStudentName(String id) {
    return students.firstWhere((s) => s.id == id).name;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = violations.where((v) {
      final name = getStudentName(v.studentId).toLowerCase();
      return name.contains(searchText.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Violation Dashboard')),

      body: Column(
        children: [

          /// 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search student...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),
          ),

          /// LIST
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No results'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final v = filtered[index];

                      return Card(
                        child: ListTile(
                          title: Text(getStudentName(v.studentId)),
                          subtitle: Text(
                            "${v.type.name} - ${v.remarks}",
                          ),

                          /// ✏️ EDIT + 🗑 DELETE
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [

                              /// EDIT
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddViolationScreen(editViolation: v),
                                    ),
                                  );
                                  setState(() {});
                                },
                              ),

                              /// DELETE
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    violations.remove(v);
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Deleted')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddViolationScreen(),
            ),
          );
          setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// ================= ADD / EDIT =================

class AddViolationScreen extends StatefulWidget {
  final Violation? editViolation;

  const AddViolationScreen({super.key, this.editViolation});

  @override
  State<AddViolationScreen> createState() => _AddViolationScreenState();
}

class _AddViolationScreenState extends State<AddViolationScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _studentId;
  ViolationType? _violationType;
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.editViolation != null) {
      _studentId = widget.editViolation!.studentId;
      _violationType = widget.editViolation!.type;
      _remarksController.text = widget.editViolation!.remarks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editViolation != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Violation' : 'Add Violation'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              /// STUDENT
              DropdownButtonFormField<String>(
                value: _studentId,
                hint: const Text('Select Student'),
                items: students.map((student) {
                  return DropdownMenuItem(
                    value: student.id,
                    child: Text(student.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _studentId = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select student' : null,
              ),

              const SizedBox(height: 10),

              /// TYPE
              DropdownButtonFormField<ViolationType>(
                value: _violationType,
                hint: const Text('Violation Type'),
                items: ViolationType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _violationType = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Select type' : null,
              ),

              const SizedBox(height: 10),

              /// REMARKS
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              /// SAVE BUTTON
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {

                    if (isEdit) {
                      widget.editViolation!
                        ..studentId = _studentId!
                        ..type = _violationType!
                        ..remarks = _remarksController.text;
                    } else {
                      final newViolation = Violation(
                        id: DateTime.now().toString(),
                        studentId: _studentId!,
                        type: _violationType!,
                        date: DateTime.now(),
                        remarks: _remarksController.text,
                        status: ViolationStatus.pending,
                        offenseCount: 1,
                        reportedBy: 'Guard',
                      );

                      violations.add(newViolation);
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Updated' : 'Added'),
                      ),
                    );

                    Navigator.pop(context);
                  }
                },
                child: Text(isEdit ? 'Update' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}