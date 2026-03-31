import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/field_encryption_service.dart';
import '../../core/state/auth_provider.dart';

class SyncPassphraseScreen extends ConsumerStatefulWidget {
  final bool isNewAccount;
  final VoidCallback onComplete;

  const SyncPassphraseScreen({
    super.key,
    required this.isNewAccount,
    required this.onComplete,
  });

  @override
  ConsumerState<SyncPassphraseScreen> createState() =>
      _SyncPassphraseScreenState();
}

class _SyncPassphraseScreenState extends ConsumerState<SyncPassphraseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passphraseCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  String? _errorMessage;
  final _encryptionService = FieldEncryptionService();

  @override
  void dispose() {
    _passphraseCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _setPassphrase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uid = ref.read(userIdProvider);
      if (uid == null) throw Exception('Not authenticated');

      await _encryptionService.setSyncPassphrase(uid, _passphraseCtrl.text);
      widget.onComplete();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to set passphrase. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enterPassphrase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uid = ref.read(userIdProvider);
      if (uid == null) throw Exception('Not authenticated');

      final success = await _encryptionService.recoverSyncKey(
        uid,
        _passphraseCtrl.text,
      );

      if (success) {
        widget.onComplete();
      } else {
        setState(() => _errorMessage = 'Incorrect passphrase. Please try again.');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to verify passphrase.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.isNewAccount
                      ? 'Set Sync Passphrase'
                      : 'Enter Sync Passphrase',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isNewAccount
                      ? 'This passphrase encrypts your health data for syncing across devices. Keep it safe \u2014 it cannot be recovered.'
                      : 'Enter the passphrase you set when you created your account to unlock your health data on this device.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _passphraseCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Sync Passphrase',
                    prefixIcon: const Icon(Icons.key_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a passphrase';
                    }
                    if (widget.isNewAccount && value.length < 8) {
                      return 'Passphrase must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                if (widget.isNewAccount) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Confirm Passphrase',
                      prefixIcon: const Icon(Icons.key_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                    validator: (value) {
                      if (value != _passphraseCtrl.text) {
                        return 'Passphrases do not match';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                if (widget.isNewAccount)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.onTertiaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Write this down! You\'ll need it to access your data on a new device.',
                            style: TextStyle(
                              color: theme.colorScheme.onTertiaryContainer,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _isLoading
                        ? null
                        : (widget.isNewAccount
                            ? _setPassphrase
                            : _enterPassphrase),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.isNewAccount ? 'Set Passphrase' : 'Unlock'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
