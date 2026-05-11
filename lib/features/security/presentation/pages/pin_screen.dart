import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/security_provider.dart';

enum PinMode { unlock, setup, confirm, change }

class PinScreen extends ConsumerStatefulWidget {
  final PinMode mode;
  final VoidCallback? onSuccess;

  const PinScreen({super.key, required this.mode, this.onSuccess});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _input = '';
  String? _firstPin;
  String _title = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _updateTitle();
  }

  void _updateTitle() {
    _title = switch (widget.mode) {
      PinMode.unlock => S.pinEnter,
      PinMode.setup when _firstPin == null => S.pinNew,
      PinMode.setup => S.pinConfirm,
      PinMode.confirm => S.pinCurrent,
      PinMode.change when _firstPin == null => S.pinNew,
      PinMode.change => S.pinConfirm,
    };
  }

  void _onKeyTap(String key) {
    if (_input.length >= 4) return;
    setState(() {
      _input += key;
      _error = null;
    });
    if (_input.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _onComplete);
    }
  }

  void _onDelete() {
    if (_input.isEmpty) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _error = null;
    });
  }

  void _onComplete() {
    switch (widget.mode) {
      case PinMode.unlock:
        _handleUnlock();
      case PinMode.setup:
      case PinMode.change:
        _handleSetup();
      case PinMode.confirm:
        _handleConfirm();
    }
  }

  void _handleUnlock() {
    final security = ref.read(securityProvider);
    if (_input == security.pin) {
      ref.read(isUnlockedProvider.notifier).state = true;
      widget.onSuccess?.call();
    } else {
      setState(() {
        _input = '';
        _error = S.pinWrong;
      });
    }
  }

  void _handleSetup() {
    if (_firstPin == null) {
      setState(() {
        _firstPin = _input;
        _input = '';
        _updateTitle();
      });
    } else {
      if (_input == _firstPin) {
        ref.read(securityProvider.notifier).state =
            ref.read(securityProvider).copyWith(pinEnabled: true, pin: _input);
        widget.onSuccess?.call();
        if (mounted) Navigator.of(context).pop(true);
      } else {
        setState(() {
          _input = '';
          _firstPin = null;
          _error = S.pinMismatch;
          _updateTitle();
        });
      }
    }
  }

  void _handleConfirm() {
    final security = ref.read(securityProvider);
    if (_input == security.pin) {
      widget.onSuccess?.call();
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() {
        _input = '';
        _error = S.pinWrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = widget.mode != PinMode.unlock;

    return PopScope(
      canPop: canPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: canPop
            ? AppBar(backgroundColor: Colors.transparent, elevation: 0)
            : null,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),
              Text(_title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _input.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: _error != null
                            ? Colors.red
                            : theme.colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 20,
                child: _error != null
                    ? Text(_error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13))
                    : null,
              ),
              const Spacer(flex: 1),
              _Keypad(onKeyTap: _onKeyTap, onDelete: _onDelete),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final ValueChanged<String> onKeyTap;
  final VoidCallback onDelete;
  const _Keypad({required this.onKeyTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];
    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) return const SizedBox(width: 80, height: 64);
            if (key == 'del') {
              return SizedBox(
                width: 80, height: 64,
                child: IconButton(
                    icon: const Icon(Icons.backspace_outlined),
                    onPressed: onDelete),
              );
            }
            return SizedBox(
              width: 80, height: 64,
              child: TextButton(
                onPressed: () => onKeyTap(key),
                child: Text(key, style: const TextStyle(fontSize: 28)),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
