@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taro_ui/taro_ui.dart';

import '../helpers/golden/golden_matrix.dart';
import '../helpers/golden/golden_sizes.dart';

/// Goldens of the Phase 15 inputs: `TaroIconButton`, `TaroTextField`,
/// `TaroChip`, `TaroRadioTile`, `WeekdayPicker`, `TaroAccordion`,
/// `TaroTabStrip` (navigation: + `kTabletIpad13`) and `StepIndicator` —
/// light/dark × en/ar at `kPhoneSmall`, 200 % text for the text-heavy ones.
void main() {
  String t(GoldenVariant v, String en, String ar) =>
      v.locale.languageCode == 'ar' ? ar : en;
  void noop() {}

  goldenMatrix(
    'taro_icon_button_chip',
    (v) => SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Row(
            children: [
              TaroIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                semanticsLabel: t(v, 'Back', 'رجوع'),
                onPressed: noop,
              ),
              TaroIconButton(
                icon: Icons.star_border_rounded,
                selectedIcon: Icons.star_rounded,
                toggled: true,
                semanticsLabel: t(v, 'Favourite', 'مفضلة'),
                onPressed: noop,
              ),
              TaroIconButton(
                icon: Icons.ios_share_rounded,
                semanticsLabel: t(v, 'Export', 'تصدير'),
                onPressed: null,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TaroChip.filter(
                label: t(v, 'All', 'الكل'),
                selected: true,
                onSelected: (_) {},
              ),
              TaroChip.filter(
                label: t(v, 'Favourites', 'المفضلة'),
                selected: false,
                onSelected: (_) {},
              ),
              TaroChip.suggestion(
                label: t(v, 'A decision at work', 'قرار في العمل'),
                leading: const Icon(Icons.lightbulb_outline_rounded),
                onPressed: noop,
              ),
              TaroChip.suggestion(
                label: t(v, 'Unavailable', 'غير متاح'),
                onPressed: null,
              ),
            ],
          ),
          StepIndicator(
            current: 2,
            total: 3,
            semanticsLabel: t(v, 'Step 2 of 3', 'الخطوة ٢ من ٣'),
          ),
        ],
      ),
    ),
    phoneSizes: const [kPhoneSmall],
  );

  goldenMatrix(
    'taro_text_field',
    (v) => SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        spacing: 16,
        children: [
          TaroTextField(
            style: TaroTextFieldStyle.search,
            hintText: t(v, 'Search questions and notes', 'ابحث في الأسئلة'),
            clearLabel: t(v, 'Clear search', 'مسح البحث'),
          ),
          TaroTextField(
            style: TaroTextFieldStyle.multiLine,
            label: t(v, 'Your question', 'سؤالك'),
            controller: TextEditingController(
              text: t(
                v,
                'How can I rebuild after a hard year at work? ' * 6,
                'كيف أعيد البناء بعد عام صعب في العمل؟ ' * 7,
              ),
            ),
            maxGraphemes: 300,
            helperText: t(v, 'Saved on this device', 'محفوظ على هذا الجهاز'),
          ),
          TaroTextField(
            label: t(v, 'Type DELETE to confirm', 'اكتب DELETE للتأكيد'),
            controller: TextEditingController(text: 'DELET'),
            errorText: t(v, "That doesn't match.", 'لا يتطابق.'),
          ),
          TaroTextField(
            hintText: t(v, 'Disabled', 'معطّل'),
            enabled: false,
          ),
        ],
      ),
    ),
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );

  goldenMatrix(
    'taro_radio_tile',
    (v) => SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        spacing: 12,
        children: [
          TaroRadioTile<int>(
            value: 0,
            groupValue: 0,
            style: TaroRadioTileStyle.card,
            title: t(v, 'Merge', 'دمج'),
            subtitle: t(
              v,
              'Keep your journal and add the readings from the file.',
              'احتفظ بدفترك وأضف القراءات من الملف.',
            ),
            onChanged: (_) {},
          ),
          TaroRadioTile<int>(
            value: 1,
            groupValue: 0,
            style: TaroRadioTileStyle.card,
            title: t(v, 'Replace', 'استبدال'),
            subtitle: t(
              v,
              'Use only the readings from the file.',
              'استخدم القراءات من الملف فقط.',
            ),
            onChanged: (_) {},
          ),
          TaroRadioTile<int>(
            value: 2,
            groupValue: 2,
            title: t(v, 'Use phone language', 'استخدم لغة الهاتف'),
            subtitle: t(v, 'English', 'العربية'),
            onChanged: (_) {},
          ),
          TaroRadioTile<int>(
            value: 3,
            groupValue: 2,
            title: t(v, 'Deutsch', 'Deutsch'),
            onChanged: null,
          ),
        ],
      ),
    ),
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );

  goldenMatrix(
    'weekday_picker_accordion',
    (v) => SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(16),
      child: Column(
        spacing: 16,
        children: [
          WeekdayPicker(
            selected: const {1, 3, 5},
            shortLabels: v.locale.languageCode == 'ar'
                ? const ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح']
                : const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
            fullLabels: const [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
              'Sunday',
            ],
            firstWeekday: v.locale.languageCode == 'ar'
                ? DateTime.saturday
                : DateTime.monday,
            onChanged: (_) {},
          ),
          TaroAccordion.text(
            title: t(
              v,
              'Why did my reading not finish?',
              'لماذا لم تكتمل قراءتي؟',
            ),
            body: t(
              v,
              'Nothing was used. Try again when you are back online.',
              'لم يُستخدم أي شيء. حاول مرة أخرى عند الاتصال.',
            ),
            initiallyExpanded: true,
          ),
          TaroAccordion.text(
            title: t(v, 'How do free readings work?', 'كيف تعمل القراءات؟'),
            body: '',
          ),
        ],
      ),
    ),
    phoneSizes: const [kPhoneSmall],
    largeText: true,
  );

  goldenMatrix(
    'taro_tab_strip',
    (v) => Column(
      children: [
        TaroTabStrip(
          labels: [
            t(v, 'Disclaimer', 'إخلاء المسؤولية'),
            t(v, 'Terms of use', 'شروط الاستخدام'),
            t(v, 'Privacy policy', 'سياسة الخصوصية'),
            t(v, 'Open-source licences', 'تراخيص المصادر المفتوحة'),
          ],
          selectedIndex: 1,
          onSelected: (_) {},
        ),
      ],
    ),
    keyScreen: true,
    phoneSizes: const [kPhoneSmall],
    tabletSizes: const [kTabletIpad13],
  );
}
