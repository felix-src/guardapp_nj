import 'package:flutter/material.dart';

import 'org_models.dart';

class Position {
  final int orgElementId;
  final String dutyRole;

  Position(this.orgElementId, this.dutyRole);
}

/// Platoon -> squad/section -> duty role dropdowns over a unit's structure.
/// Each choice narrows the next; [onChanged] gets null until all are picked.
/// Use inside a Form: every dropdown validates as required.
class PositionPicker extends StatefulWidget {
  final List<OrgElement> structure;
  final Position? initial;
  final ValueChanged<Position?> onChanged;

  const PositionPicker({
    super.key,
    required this.structure,
    required this.onChanged,
    this.initial,
  });

  @override
  State<PositionPicker> createState() => _PositionPickerState();
}

class _PositionPickerState extends State<PositionPicker> {
  OrgElement? _top; // Company HQ or a platoon
  OrgElement? _child; // HQ or squad inside the chosen platoon
  String? _role;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;

    for (final top in widget.structure) {
      if (top.id == initial.orgElementId) {
        _top = top;
      } else if (findOrgElement(top.children, initial.orgElementId)
          case final child?) {
        _top = top;
        _child = child;
      }
    }
    if (_leaf?.roles.any((r) => r.key == initial.dutyRole) ?? false) {
      _role = initial.dutyRole;
    }
  }

  /// The element that actually holds members.
  OrgElement? get _leaf => (_top?.isPlatoon ?? false) ? _child : _top;

  void _notify() {
    final leaf = _leaf;
    final role = _role;
    widget.onChanged(
      leaf != null && role != null ? Position(leaf.id, role) : null,
    );
  }

  String? _required(Object? value) => value == null ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final top = _top;
    final leaf = _leaf;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<OrgElement>(
          initialValue: top,
          decoration: const InputDecoration(labelText: 'Platoon / section'),
          isExpanded: true,
          items: [
            for (final el in widget.structure)
              DropdownMenuItem(value: el, child: Text(el.name)),
          ],
          onChanged: (value) {
            setState(() {
              _top = value;
              _child = null;
              _role = null;
            });
            _notify();
          },
          validator: _required,
        ),
        if (top != null && top.isPlatoon) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<OrgElement>(
            // New key per platoon so the field resets when the platoon changes
            key: ValueKey('child-${top.id}'),
            initialValue: _child,
            decoration: const InputDecoration(labelText: 'Squad / HQ'),
            isExpanded: true,
            items: [
              for (final el in top.children)
                DropdownMenuItem(value: el, child: Text(el.name)),
            ],
            onChanged: (value) {
              setState(() {
                _child = value;
                _role = null;
              });
              _notify();
            },
            validator: _required,
          ),
        ],
        if (leaf != null) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: ValueKey('role-${leaf.id}'),
            initialValue: _role,
            decoration: const InputDecoration(labelText: 'Duty role'),
            isExpanded: true,
            items: [
              for (final role in leaf.roles)
                DropdownMenuItem(value: role.key, child: Text(role.label)),
            ],
            onChanged: (value) {
              setState(() => _role = value);
              _notify();
            },
            validator: _required,
          ),
        ],
      ],
    );
  }
}
