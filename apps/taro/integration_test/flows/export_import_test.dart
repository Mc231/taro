import 'package:flutter/material.dart' show TextField;

import '../support/flow_harness.dart';

/// F5 (01 §7.11, §9.5; 06 §4): journal entries → S24 export (share sheet)
/// → S26 delete all data (the credits stay, RC37) → S25 import the file
/// with **Replace** → the entries are back; the balance never moves (it
/// is not in the backup).
void main() {
  taroFlow('export, wipe, import (replace): entries back', ($) async {
    final fakes = flowFakes();
    final paid = aCreditBalance().withFreeRemaining(0).withPaid(7).build();
    fakes.balance = FakeBalanceRepository(cached: paid, server: paid);
    const questions = ['Where is my focus?', 'What should I let go of?'];
    for (final (i, q) in questions.indexed) {
      fakes.journal.putReading(
        aReading()
            .withId('0c6e2b1e-1111-4222-8333-44445555666$i')
            .withQuestion(q)
            .withNote('note $i')
            .build(),
      );
    }

    final app = await FlowApp.launch($, fakes: fakes);
    final l = app.l10n();
    await app.waitForScreen(ScreenId.s05);
    await app.tapText(l.tabJournal);
    await app.waitForScreen(ScreenId.s14);
    for (final q in questions) {
      await app.waitFor(find.text(q));
    }

    // Export.
    await app.tapText(l.tabSettings);
    await app.waitForScreen(ScreenId.s20);
    await app.tapText(l.settingsExport);
    await app.waitForScreen(ScreenId.s24);
    await app.tapButton(l.exportButton);
    await app.waitUntil(() => fakes.files.shared.isNotEmpty);
    final file = fakes.files.shared.single;
    await app.tapFinder(find.bySemanticsLabel(l.commonBack));
    await app.waitForScreen(ScreenId.s20);

    // Wipe (S26): the journal goes, the credits stay (RC37).
    await app.tapText(l.settingsDeleteAll);
    await app.waitForScreen(ScreenId.s26);
    // The field sits under the panels: scroll it in on short phones.
    await app.$(TextField).scrollTo();
    await app.$(TextField).enterText(l.deleteConfirmWord);
    await app.tapButton(l.deleteButton);
    await app.waitFor(find.text(l.deleteDoneTitle));
    expect(fakes.journal.readings, isEmpty);
    expect(fakes.balance.cached, paid);
    await app.tapButton(l.commonDone);

    // Import with Replace (Done left for Today).
    await app.waitForScreen(ScreenId.s05);
    // The Settings tab keeps its stack: a second tap resets it to S20.
    await app.tapText(l.tabSettings);
    await app.tapText(l.tabSettings);
    await app.waitForScreen(ScreenId.s20);
    fakes.files.willPick(file.bytes);
    await app.tapText(l.settingsImport);
    await app.waitForScreen(ScreenId.s25);
    await app.tapButton(l.importChooseFile);
    await app.waitFor(find.text(l.importChecked));
    await app.tapText(l.importReplace);
    await app.tapButton(l.importButton);
    if (find.text(l.importConfirmReplaceAction).evaluate().isNotEmpty) {
      await app.tapButton(l.importConfirmReplaceAction);
    }
    await app.waitFor(find.text(l.importDone(2, 0)));
    await app.tapButton(l.importOpenJournal);
    await app.waitForScreen(ScreenId.s14);
    for (final q in questions) {
      await app.waitFor(find.text(q));
    }
    expect(fakes.journal.readings, hasLength(2));
    expect(
      fakes.journal.readings.values.map((r) => r.note).toSet(),
      {'note 0', 'note 1'},
    );
    // Credits untouched: the balance is not part of a backup.
    expect(fakes.balance.cached, paid);
    expect(fakes.balance.applied, isEmpty);
  });
}
