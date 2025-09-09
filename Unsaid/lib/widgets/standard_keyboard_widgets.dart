import 'package:flutter/material.dart';

/// Utility class for managing keyboard preferences in specific contexts
class StandardKeyboardWidget extends StatelessWidget {
  final Widget child;
  final bool forceStandardKeyboard;

  const StandardKeyboardWidget({
    super.key,
    required this.child,
    this.forceStandardKeyboard = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!forceStandardKeyboard) {
      return child;
    }

    return MediaQuery(
      // Override keyboard settings to ensure standard iOS keyboard
      data: MediaQuery.of(context).copyWith(
        // Prevent custom keyboard extensions from interfering
        textScaler: TextScaler.linear(MediaQuery.of(context).textScaleFactor),
      ),
      child: child,
    );
  }
}

/// Creates a TextField configured to use the standard iOS keyboard
class StandardTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final InputDecoration? decoration;
  final bool enabled;
  final FocusNode? focusNode;

  const StandardTextField({
    super.key,
    this.controller,
    this.hintText,
    this.maxLines,
    this.minLines,
    this.onSubmitted,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.decoration,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return StandardKeyboardWidget(
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: keyboardType ?? TextInputType.text,
        textInputAction: textInputAction ?? TextInputAction.send,
        maxLines: maxLines,
        minLines: minLines,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        decoration: decoration ?? InputDecoration(
          hintText: hintText ?? 'Type your message...',
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(12),
        ),
        // Ensure we're using the standard text input behavior
        autocorrect: true,
        enableSuggestions: true,
        smartDashesType: SmartDashesType.enabled,
        smartQuotesType: SmartQuotesType.enabled,
      ),
    );
  }
}

/// Creates a TextFormField configured to use the standard iOS keyboard
class StandardTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final InputDecoration? decoration;
  final bool enabled;
  final FocusNode? focusNode;

  const StandardTextFormField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.maxLines,
    this.minLines,
    this.onSubmitted,
    this.onChanged,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.decoration,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return StandardKeyboardWidget(
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        keyboardType: keyboardType ?? TextInputType.text,
        textInputAction: textInputAction ?? TextInputAction.send,
        maxLines: maxLines,
        minLines: minLines,
        onFieldSubmitted: onSubmitted,
        onChanged: onChanged,
        validator: validator,
        decoration: decoration ?? InputDecoration(
          hintText: hintText,
          labelText: labelText,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(12),
        ),
        // Ensure we're using the standard text input behavior
        autocorrect: true,
        enableSuggestions: true,
        smartDashesType: SmartDashesType.enabled,
        smartQuotesType: SmartQuotesType.enabled,
      ),
    );
  }
}
