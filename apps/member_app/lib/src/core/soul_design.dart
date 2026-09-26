import 'package:flutter/material.dart';

import 'soul_theme.dart';

abstract final class SoulDesign {
  static const horizontalPadding = 24.0;
  static const cardRadius = 12.0;
  static const buttonRadius = 8.0;
  static const headerGap = 22.0;
}

class SoulTopBar extends StatelessWidget {
  const SoulTopBar({
    super.key,
    this.onBack,
    this.onInfo,
    this.title,
    this.trailing,
  });

  final VoidCallback? onBack;
  final VoidCallback? onInfo;
  final String? title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: onBack == null
                  ? null
                  : IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 22,
                        color: SoulColors.ink,
                      ),
                    ),
            ),
            Expanded(
              child: title == null
                  ? const SizedBox.shrink()
                  : Text(
                      title!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: SoulColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
            SizedBox(
              width: 44,
              child: trailing ??
                  (onInfo == null
                      ? null
                      : IconButton(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          onPressed: onInfo,
                          icon: const Icon(
                            Icons.info_outline_rounded,
                            size: 22,
                            color: SoulColors.ink,
                          ),
                        )),
            ),
          ],
        ),
      );
}

class SoulProgressLine extends StatelessWidget {
  const SoulProgressLine({
    super.key,
    required this.value,
  });

  final double value;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          minHeight: 4,
          color: SoulColors.limeLight,
          backgroundColor: const Color(0xffeceee8),
        ),
      );
}

class SoulPrimaryButton extends StatelessWidget {
  const SoulPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: SoulColors.limeLight,
            foregroundColor: SoulColors.ink,
            disabledBackgroundColor: const Color(0xffe7edcc),
            disabledForegroundColor: SoulColors.muted,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SoulDesign.buttonRadius),
            ),
          ),
          child: busy
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SoulColors.ink,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 19),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      );
}

class SoulChoiceTile extends StatelessWidget {
  const SoulChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.trailingChevron = false,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final bool trailingChevron;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        button: true,
        selected: selected,
        label: label,
        hint: subtitle,
        onTap: onTap,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(SoulDesign.cardRadius),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(SoulDesign.cardRadius),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                constraints: const BoxConstraints(minHeight: 58),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SoulDesign.cardRadius),
                  border: Border.all(
                    color: selected ? SoulColors.limeLight : SoulColors.line,
                    width: selected ? 1.6 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: SoulColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null && subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: const TextStyle(
                                color: SoulColors.muted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailingChevron)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: SoulColors.muted,
                      )
                    else
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? SoulColors.limeLight
                                : const Color(0xffd9ddd2),
                            width: 1.5,
                          ),
                        ),
                        child: selected
                            ? Center(
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: SoulColors.limeLight,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class SoulStepScaffold extends StatelessWidget {
  const SoulStepScaffold({
    super.key,
    required this.progress,
    required this.child,
    required this.onBack,
    this.onInfo,
    this.footer,
    this.title,
    this.backgroundColor = Colors.white,
  });

  final double progress;
  final Widget child;
  final VoidCallback onBack;
  final VoidCallback? onInfo;
  final Widget? footer;
  final String? title;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SoulDesign.horizontalPadding - 8,
                    7,
                    SoulDesign.horizontalPadding - 8,
                    0,
                  ),
                  child: SoulTopBar(
                    onBack: onBack,
                    onInfo: onInfo,
                    title: title,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    SoulDesign.horizontalPadding,
                    7,
                    SoulDesign.horizontalPadding,
                    0,
                  ),
                  child: SoulProgressLine(value: progress),
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SoulDesign.horizontalPadding,
                    ),
                    child: child,
                  ),
                ),
                if (footer != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      SoulDesign.horizontalPadding,
                      12,
                      SoulDesign.horizontalPadding,
                      18 + MediaQuery.paddingOf(context).bottom * .35,
                    ),
                    child: footer!,
                  ),
              ],
            ),
          ),
        ),
      );
}

class SoulPageTitle extends StatelessWidget {
  const SoulPageTitle(
    this.title, {
    super.key,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: SoulColors.ink,
              fontSize: 24,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -.35,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(
                color: SoulColors.muted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ],
      );
}

class SoulSearchField extends StatelessWidget {
  const SoulSearchField({
    super.key,
    required this.controller,
    this.hint = 'Search here...',
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          fillColor: SoulColors.softSurface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: SoulColors.limeLight,
              width: 1.2,
            ),
          ),
        ),
      );
}
