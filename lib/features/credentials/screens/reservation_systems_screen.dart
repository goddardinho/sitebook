import 'package:flutter/material.dart';
import '../models/reservation_credential.dart';
import '../services/credential_storage_service.dart';

class ReservationSystemsScreen extends StatefulWidget {
  const ReservationSystemsScreen({super.key});

  @override
  State<ReservationSystemsScreen> createState() =>
      _ReservationSystemsScreenState();
}

class _ReservationSystemsScreenState extends State<ReservationSystemsScreen> {
  final CredentialStorageService _storage = CredentialStorageService();
  List<ReservationCredential> _credentials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    var creds = await _storage.loadCredentials();
    if (creds.isEmpty) {
      // Pre-populate with recreation.gov
      final defaultCred = ReservationCredential(
        id: 'recreation-gov',
        name: 'National Park (recreation.gov)',
        url: 'https://www.recreation.gov/',
        username: '',
        password: '',
      );
      await _storage.upsertCredential(defaultCred);
      creds = [defaultCred];
    }
    setState(() {
      _credentials = creds;
      _loading = false;
    });
  }

  void _showAddOrEditDialog([ReservationCredential? credential]) async {
    final result = await showDialog<ReservationCredential>(
      context: context,
      builder: (context) => ReservationCredentialDialog(credential: credential),
    );
    if (result != null) {
      await _storage.upsertCredential(result);
      _loadCredentials();
    }
  }

  void _removeCredential(String id) async {
    await _storage.removeCredential(id);
    _loadCredentials();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reservation Systems')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _credentials.length,
              itemBuilder: (context, index) {
                final cred = _credentials[index];
                return ListTile(
                  title: Text(cred.name),
                  subtitle: Text(cred.url),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showAddOrEditDialog(cred),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeCredential(cred.id),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOrEditDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ReservationCredentialDialog extends StatefulWidget {
  final ReservationCredential? credential;
  const ReservationCredentialDialog({this.credential, super.key});

  @override
  State<ReservationCredentialDialog> createState() =>
      _ReservationCredentialDialogState();
}

class _ReservationCredentialDialogState
    extends State<ReservationCredentialDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.credential?.name ?? '',
    );
    _urlController = TextEditingController(text: widget.credential?.url ?? '');
    _usernameController = TextEditingController(
      text: widget.credential?.username ?? '',
    );
    _passwordController = TextEditingController(
      text: widget.credential?.password ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.credential == null
            ? 'Add Reservation System'
            : 'Edit Reservation System',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'URL'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              final cred = ReservationCredential(
                id: widget.credential?.id ?? UniqueKey().toString(),
                name: _nameController.text.trim(),
                url: _urlController.text.trim(),
                username: _usernameController.text.trim(),
                password: _passwordController.text,
              );
              Navigator.of(context).pop(cred);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
