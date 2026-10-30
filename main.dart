import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

// ====== À MODIFIER ======
const String emailDest = "1lavo.maroc@email.com";
// ========================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const LavoApp());
}

class Pal {
  final Color acc, acc2, bg, sheet, card, line, txt, mut, mapbg, road, block, err;
  final bool dark;
  const Pal({required this.acc, required this.acc2, required this.bg, required this.sheet, required this.card, required this.line, required this.txt, required this.mut, required this.mapbg, required this.road, required this.block, required this.err, required this.dark});
  static const light = Pal(acc: Color(0xFF0D47A1), acc2: Color(0xFF1976D2), bg: Color(0xFFEAF2FC), sheet: Color(0xFFFFFFFF), card: Color(0xFFF1F6FD), line: Color(0xFFD5E3F5), txt: Color(0xFF0B2545), mut: Color(0xFF64748B), mapbg: Color(0xFFDBE9FA), road: Color(0xFFFFFFFF), block: Color(0xFFC7DCF5), err: Color(0xFFD32F2F), dark: false);
  static const night = Pal(acc: Color(0xFF2F80ED), acc2: Color(0xFF4C9AFF), bg: Color(0xFF101418), sheet: Color(0xFF1C2026), card: Color(0xFF272C33), line: Color(0xFF343A42), txt: Color(0xFFF2F5F8), mut: Color(0xFF9AA5B1), mapbg: Color(0xFF262B31), road: Color(0xFF3A424B), block: Color(0xFF2D333A), err: Color(0xFFD32F2F), dark: true);
  static Pal of(BuildContext c) => MediaQuery.platformBrightnessOf(c) == Brightness.dark ? night : light;
}

class Svc {
  final String n, d;
  final List<int> p;
  final String? tag;
  const Svc(this.n, this.d, this.p, [this.tag]);
}

const List<List<String>> sizes = [
  ["S", "Petite", "Citadine"],
  ["M", "Moyenne", "Berline / SUV compact"],
  ["L", "Grande", "Berline / SUV"],
  ["XL", "Très grande", "4x4 / Van"],
];
const List<Svc> svcs = [
  Svc("Extérieur", "Lavage, jantes, séchage et finition", [30, 30, 40, 60]),
  Svc("Intérieur", "Aspiration, vitres, tableau de bord, parfum", [40, 50, 60, 70]),
  Svc("Complet", "Extérieur + intérieur, finition brillance", [50, 60, 70, 80], "Le + demandé"),
  Svc("Gold", "Complet + détachage, cire, moteur, parfum premium", [90, 120, 140, 160]),
];

class LavoApp extends StatelessWidget {
  const LavoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "1LAVO – Réservation",
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF0D47A1)),
      home: const BookingPage(),
    );
  }
}

class MapPainter extends CustomPainter {
  final Pal p;
  MapPainter(this.p);
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, Paint()..color = p.mapbg);
    final sc = math.max(s.width / 400, s.height / 320);
    c.save();
    c.clipRect(Offset.zero & s);
    c.translate((s.width - 400 * sc) / 2, (s.height - 320 * sc) / 2);
    c.scale(sc);
    final blk = Paint()..color = p.block;
    for (final r in const [
      [10, 20, 90, 70], [120, 10, 110, 60], [250, 25, 130, 65], [20, 120, 70, 80], [250, 130, 60, 70],
      [330, 125, 60, 85], [30, 235, 120, 70], [190, 240, 90, 70], [300, 240, 90, 70]
    ]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r[0].toDouble(), r[1].toDouble(), r[2].toDouble(), r[3].toDouble()), const Radius.circular(6)), blk);
    }
    Paint road(double w) => Paint()..color = p.road..style = PaintingStyle.stroke..strokeWidth = w..strokeCap = StrokeCap.round;
    Path line(double x1, double y1, double x2, double y2) => Path()..moveTo(x1, y1)..lineTo(x2, y2);
    c.drawPath(line(-10, 105, 410, 112), road(12));
    c.drawPath(line(-10, 222, 410, 215), road(12));
    c.drawPath(line(110, -10, 118, 330), road(12));
    c.drawPath(line(235, -10, 240, 330), road(12));
    c.drawPath(Path()..moveTo(-10, 30)..quadraticBezierTo(200, 60, 410, 20), road(7));
    final car = Paint()..color = const Color(0xBF0D47A1);
    for (final r in const [[60, 98, 22, 11], [305, 205, 22, 11], [104, 260, 11, 22], [232, 60, 11, 22]]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r[0].toDouble(), r[1].toDouble(), r[2].toDouble(), r[3].toDouble()), const Radius.circular(5)), car);
    }
    c.restore();
  }
  @override
  bool shouldRepaint(covariant MapPainter old) => old.p != p;
}

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});
  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final adr = TextEditingController(), modele = TextEditingController(), couleur = TextEditingController(), plaque = TextEditingController();
  final note = TextEditingController(), nom = TextEditingController(), tel = TextEditingController(), tel2 = TextEditingController();
  final adrFocus = FocusNode();
  final scroll = ScrollController();
  final offset = ValueNotifier<double>(0);
  final keys = {for (final k in ["adr", "svc", "size", "date", "nom", "tel", "tel2"]) k: GlobalKey()};
  int size = -1, svc = -1;
  String? gps, heure;
  DateTime? date;
  String bub = "Votre adresse", gpsTxt = "Utiliser ma position GPS";
  Set<String> bad = {};
  bool eSize = false, eSvc = false, done = false;
  String recap = "", mailto = "", gmail = "";
  String copyLabel = "Copier la demande", copyAdrLabel = "Copier l’adresse $emailDest";
  final hours = <String>[
    for (int t = 8; t <= 19; t++) ...[
      "${t.toString().padLeft(2, '0')}:00",
      if (t != 19) "${t.toString().padLeft(2, '0')}:30",
    ]
  ];

  @override
  void initState() {
    super.initState();
    scroll.addListener(() => offset.value = scroll.hasClients ? scroll.offset : 0);
    adrFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [adr, modele, couleur, plaque, note, nom, tel, tel2]) {
      c.dispose();
    }
    adrFocus.dispose();
    scroll.dispose();
    super.dispose();
  }

  String cleanTel(String v) {
    v = v.replaceAll(RegExp(r"[\s.\-()]"), "");
    if (v.startsWith("+212")) return "0${v.substring(4)}";
    if (v.startsWith("00212")) return "0${v.substring(5)}";
    return v;
  }

  bool validTel(String v) => RegExp(r"^0[5-7]\d{8}$").hasMatch(v);
  String fmtDate(DateTime d) => "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  Future<void> locate() async {
    setState(() => gpsTxt = "Localisation en cours…");
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception("off");
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) throw Exception("denied");
      final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)));
      setState(() {
        gps = "https://maps.google.com/?q=${pos.latitude.toStringAsFixed(6)},${pos.longitude.toStringAsFixed(6)}";
        gpsTxt = "✓ Position GPS ajoutée";
        if (adr.text.trim().isEmpty) bub = "Ma position actuelle";
      });
    } catch (_) {
      setState(() => gpsTxt = "Impossible de vous localiser, écrivez l’adresse");
    }
  }

  void jumpTo(String k) {
    final c = keys[k]?.currentContext;
    if (c != null) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 300), alignment: 0.5);
  }

  void send() {
    final t = cleanTel(tel.text), t2 = cleanTel(tel2.text);
    final b = <String>{
      if (adr.text.trim().length < 5 && gps == null) "adr",
      if (nom.text.trim().length < 3) "nom",
      if (!validTel(t)) "tel",
      if (t != t2 || t2.isEmpty) "tel2",
      if (date == null) "date",
      if (heure == null) "heure",
    };
    setState(() {
      bad = b;
      eSize = size < 0;
      eSvc = svc < 0;
    });
    final first = b.contains("adr") ? "adr" : eSvc ? "svc" : eSize ? "size" : (b.contains("date") || b.contains("heure")) ? "date" : b.contains("nom") ? "nom" : b.contains("tel") ? "tel" : b.contains("tel2") ? "tel2" : null;
    if (first != null) {
      jumpTo(first);
      return;
    }
    final s = sizes[size], v = svcs[svc];
    final lines = [
      "NOUVELLE RÉSERVATION 1LAVO", "",
      "Client : ${nom.text.trim()}", "Téléphone : $t", "",
      "Adresse : ${adr.text.trim().isEmpty ? '-' : adr.text.trim()}",
      "Position GPS : ${gps ?? 'non partagée'}", "",
      "Voiture : ${s[0]} (${s[1]} – ${s[2]})",
      "Modèle : ${modele.text.trim().isEmpty ? '-' : modele.text.trim()}",
      "Couleur : ${couleur.text.trim().isEmpty ? '-' : couleur.text.trim()}",
      "Plaque : ${plaque.text.trim().isEmpty ? '-' : plaque.text.trim()}", "",
      "Formule : ${v.n}", "Prix : ${v.p[size]} MAD", "",
      "Date : ${fmtDate(date!)}", "Heure : $heure",
      "Remarques : ${note.text.trim().isEmpty ? '-' : note.text.trim()}",
    ];
    final r = lines.join("\n");
    final subj = "Réservation 1LAVO – ${nom.text.trim()} – ${fmtDate(date!)} $heure";
    setState(() {
      recap = r;
      mailto = "mailto:$emailDest?subject=${Uri.encodeComponent(subj)}&body=${Uri.encodeComponent(r)}";
      gmail = "https://mail.google.com/mail/?view=cm&fs=1&to=$emailDest&su=${Uri.encodeComponent(subj)}&body=${Uri.encodeComponent(r)}";
      copyLabel = "Copier la demande";
      copyAdrLabel = "Copier l’adresse $emailDest";
      done = true;
    });
  }

  Future<void> openUrl(String u) async {
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse(u), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impossible d’ouvrir. Utilisez « Copier la demande ».")));
    }
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = await showDatePicker(context: context, initialDate: date ?? today, firstDate: today, lastDate: today.add(const Duration(days: 365)));
    if (d != null) setState(() => date = d);
  }

  // ---------- UI helpers ----------
  InputDecoration deco(Pal p, String hint, {bool err = false}) {
    OutlineInputBorder ob(Color c) => OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: c, width: 1.5));
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: p.mut),
      filled: true,
      fillColor: p.card,
      isDense: false,
      contentPadding: const EdgeInsets.all(15),
      border: ob(err ? p.err : Colors.transparent),
      enabledBorder: ob(err ? p.err : Colors.transparent),
      focusedBorder: ob(err ? p.err : p.acc2),
    );
  }

  Widget errText(Pal p, String m) => Padding(padding: const EdgeInsets.only(top: 5), child: Text(m, style: TextStyle(color: p.err, fontSize: 12)));

  Widget input(Pal p, TextEditingController c, String hint, {String? k, String? msg, TextInputType? type, int lines = 1, List<String>? hints}) {
    final isBad = k != null && bad.contains(k);
    final f = TextField(controller: c, keyboardType: type, minLines: lines, maxLines: lines, cursorColor: p.acc2, autofillHints: hints, style: TextStyle(fontSize: 16, color: p.txt), decoration: deco(p, hint, err: isBad));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      k != null ? KeyedSubtree(key: keys[k], child: f) : f,
      if (isBad && msg != null) errText(p, msg),
    ]);
  }

  Widget h3(Pal p, String t) => Padding(padding: const EdgeInsets.only(top: 22, bottom: 10), child: Text(t, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: p.txt)));

  Widget place(Pal p, IconData ic, String label, String trail, VoidCallback onTap, {bool border = true}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(border: border ? Border(bottom: BorderSide(color: p.line)) : null),
        child: Row(children: [
          Icon(ic, color: p.mut, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontSize: 16, color: p.txt))),
          if (trail.isNotEmpty) Text(trail, style: TextStyle(fontSize: 12, color: p.mut)),
        ]),
      ),
    );
  }

  Widget svcCard(Pal p, int i, {bool big = false}) {
    final s = svcs[i];
    final on = svc == i;
    final price = size >= 0 ? "${s.p[size]} MAD" : "dès ${s.p[0]} MAD";
    final fg = big ? Colors.white : p.txt;
    final sub = big ? const Color(0xE0FFFFFF) : p.mut;
    return GestureDetector(
      onTap: () => setState(() {
        svc = i;
        eSvc = false;
      }),
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: big ? null : p.card,
          gradient: big ? LinearGradient(begin: const Alignment(-0.34, -0.94), end: const Alignment(0.34, 0.94), colors: [p.acc, p.acc2]) : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: on ? p.acc2 : Colors.transparent, width: 2),
          boxShadow: on ? const [BoxShadow(color: Color(0x474C9AFF), spreadRadius: 3)] : null,
        ),
        child: Stack(children: [
          if (big) Positioned(right: -30, bottom: -30, child: Container(width: 130, height: 130, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1FFFFFFF)))),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.n, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: fg)),
                const SizedBox(height: 4),
                Text(s.d, style: TextStyle(fontSize: 11.5, height: 1.35, color: sub)),
              ]),
              Padding(padding: const EdgeInsets.only(top: 8), child: Text(price, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: big ? const Color(0xE0FFFFFF) : p.acc2))),
            ]),
          ),
          if (s.tag != null)
            Positioned(top: 10, right: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0x38FFFFFF), borderRadius: BorderRadius.circular(10)), child: Text(s.tag!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)))),
          if (on)
            Positioned(top: 8, right: 10, child: Container(width: 22, height: 22, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: p.acc2), child: const Text("✓", style: TextStyle(color: Colors.white, fontSize: 13)))),
        ]),
      ),
    );
  }

  Widget goBtn(Pal p, String label, VoidCallback onTap) => Material(
        color: p.acc,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: Container(width: double.infinity, padding: const EdgeInsets.all(16), alignment: Alignment.center, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)))),
      );

  Widget secBtn(Pal p, String label, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap, child: Container(width: double.infinity, padding: const EdgeInsets.all(14), alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: p.acc2, width: 1.5), borderRadius: BorderRadius.circular(14)), child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: p.acc2, fontSize: 15, fontWeight: FontWeight.w700)))),
      );

  Widget fab(Pal p, IconData ic, VoidCallback onTap) => Material(
        color: p.sheet,
        shape: const CircleBorder(),
        elevation: 5,
        child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 48, height: 48, child: Icon(ic, color: p.txt, size: 22))),
      );

  void openMenu(Pal p) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Fermer",
      barrierColor: const Color(0x80000000),
      pageBuilder: (ctx, _, __) {
        final top = MediaQuery.of(ctx).padding.top;
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: p.sheet,
            child: Container(
              width: math.min(MediaQuery.of(ctx).size.width * 0.78, 320),
              height: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 30 + top, 20, 20),
              child: DefaultTextStyle(
                style: TextStyle(fontSize: 15, height: 1.7, color: p.txt),
                child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("1LAVO", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                  Text("Lavage auto professionnel sans eau."),
                  Text("On vient jusqu’à vous à Casablanca."),
                  SizedBox(height: 26),
                  Text("💧 Économie d’eau"),
                  Text("🏠 Service à domicile"),
                  Text("✨ Résultat professionnel"),
                  Text("🌿 Produits sûrs"),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    final mq = MediaQuery.of(context);
    final h = mq.size.height;
    final mapH = math.max(h * 0.42, 250.0);
    final top = mq.padding.top;

    final sheetBody = Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: h * 0.7),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 130),
      decoration: BoxDecoration(color: p.sheet, borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 24, offset: Offset(0, -6))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 44, height: 5, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(3)))),
        // Adresse
        KeyedSubtree(
          key: keys["adr"],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(16), boxShadow: adrFocus.hasFocus ? [BoxShadow(color: p.acc2, spreadRadius: 2)] : null),
            child: Row(children: [
              Icon(Icons.search, color: p.mut, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: adr,
                  focusNode: adrFocus,
                  cursorColor: p.acc2,
                  autofillHints: const [AutofillHints.fullStreetAddress],
                  style: TextStyle(fontSize: 17, color: p.txt),
                  onChanged: (v) => setState(() => bub = v.trim().isEmpty ? "Votre adresse" : v.trim()),
                  decoration: InputDecoration(hintText: "Où venir laver votre voiture ?", hintStyle: TextStyle(color: p.mut), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 17)),
                ),
              ),
            ]),
          ),
        ),
        if (bad.contains("adr")) Padding(padding: const EdgeInsets.only(left: 4), child: errText(p, "Indiquez votre adresse.")),
        place(p, Icons.location_on_outlined, "Domicile", "Casablanca", () {
          adr.text = "Domicile – ";
          adr.selection = TextSelection.collapsed(offset: adr.text.length);
          adrFocus.requestFocus();
          setState(() => bub = "Domicile –");
        }),
        place(p, Icons.location_on_outlined, "Bureau / Entreprise", "Casablanca", () {
          adr.text = "Bureau – ";
          adr.selection = TextSelection.collapsed(offset: adr.text.length);
          adrFocus.requestFocus();
          setState(() => bub = "Bureau –");
        }),
        place(p, Icons.near_me_outlined, gpsTxt, "", locate, border: false),
        // Formules
        h3(p, "Choisissez votre formule"),
        KeyedSubtree(
          key: keys["svc"],
          child: Column(children: [
            IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: svcCard(p, 0)), const SizedBox(height: 10), Expanded(child: svcCard(p, 1))])),
                const SizedBox(width: 10),
                Expanded(child: svcCard(p, 2, big: true)),
              ]),
            ),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: svcCard(p, 3)),
          ]),
        ),
        if (eSvc) errText(p, "Choisissez une formule."),
        // Taille
        h3(p, "Taille de la voiture"),
        KeyedSubtree(
          key: keys["size"],
          child: Row(children: [
            for (int i = 0; i < sizes.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    size = i;
                    eSize = false;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(color: size == i ? p.acc : p.card, borderRadius: BorderRadius.circular(16)),
                    child: Column(children: [
                      Text(sizes[i][0], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: size == i ? Colors.white : p.acc2)),
                      Text(sizes[i][1], textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, height: 1.2, color: size == i ? Colors.white : p.mut)),
                    ]),
                  ),
                ),
              ),
            ]
          ]),
        ),
        if (eSize) errText(p, "Choisissez la taille."),
        // Voiture
        h3(p, "Votre voiture"),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: input(p, modele, "Marque / modèle")),
          const SizedBox(width: 10),
          Expanded(child: input(p, couleur, "Couleur")),
        ]),
        const SizedBox(height: 10),
        input(p, plaque, "Plaque (facultatif)"),
        // Quand
        h3(p, "Quand ?"),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              KeyedSubtree(
                key: keys["date"],
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: pickDate,
                  child: Container(
                    height: 54,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: p.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bad.contains("date") ? p.err : Colors.transparent, width: 1.5)),
                    child: Row(children: [
                      Expanded(child: Text(date == null ? "Date" : fmtDate(date!), style: TextStyle(fontSize: 16, color: date == null ? p.mut : p.txt))),
                      Icon(Icons.calendar_today_outlined, size: 18, color: p.mut),
                    ]),
                  ),
                ),
              ),
              if (bad.contains("date")) errText(p, "Date requise."),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              DropdownButtonFormField<String>(
                initialValue: heure,
                isExpanded: true,
                dropdownColor: p.card,
                style: TextStyle(fontSize: 16, color: p.txt),
                hint: Text("Heure", style: TextStyle(color: p.mut)),
                decoration: deco(p, "", err: bad.contains("heure")),
                items: [for (final x in hours) DropdownMenuItem(value: x, child: Text(x))],
                onChanged: (v) => setState(() => heure = v),
              ),
              if (bad.contains("heure")) errText(p, "Heure requise."),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        input(p, note, "Remarques : étage, code d’accès…", lines: 2),
        // Coordonnées
        h3(p, "Vos coordonnées"),
        input(p, nom, "Nom complet", k: "nom", msg: "Saisissez votre nom.", hints: const [AutofillHints.name]),
        const SizedBox(height: 10),
        input(p, tel, "Téléphone : 06 12 34 56 78", k: "tel", msg: "Numéro marocain invalide.", type: TextInputType.phone, hints: const [AutofillHints.telephoneNumber]),
        const SizedBox(height: 10),
        input(p, tel2, "Confirmez votre téléphone", k: "tel2", msg: "Les numéros ne correspondent pas.", type: TextInputType.phone),
        const SizedBox(height: 24),
        DefaultTextStyle(
          style: TextStyle(fontSize: 11, color: p.mut),
          child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Text("💧\nSans eau", textAlign: TextAlign.center),
            Text("🏠\nÀ domicile", textAlign: TextAlign.center),
            Text("✨\nRésultat pro", textAlign: TextAlign.center),
            Text("🌿\nProduits sûrs", textAlign: TextAlign.center),
          ]),
        ),
      ]),
    );

    final mapLayer = Positioned(
      top: 0, left: 0, right: 0, height: mapH,
      child: Stack(children: [
        Positioned.fill(child: CustomPaint(painter: MapPainter(p))),
        Positioned(
          top: mapH / 2 - 0.78 * 136, left: 0, right: 0,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              constraints: const BoxConstraints(maxWidth: 240),
              decoration: BoxDecoration(color: p.sheet, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 14, offset: Offset(0, 4))]),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 210),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text("Point de lavage", style: TextStyle(fontSize: 11, color: p.mut)),
                  Text(bub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: p.txt)),
                ]),
              ),
            ),
            const SizedBox(height: 6),
            Container(width: 46, height: 46, decoration: BoxDecoration(color: p.acc, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 12, offset: Offset(0, 4))]), child: const Icon(Icons.water_drop, color: Colors.white, size: 26)),
            Container(width: 3, height: 22, decoration: BoxDecoration(color: p.acc, borderRadius: BorderRadius.circular(2))),
            Container(width: 12, height: 12, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF2F80ED), boxShadow: [BoxShadow(color: Color(0x402F80ED), spreadRadius: 7)])),
          ]),
        ),
      ]),
    );

    final topOverlay = ValueListenableBuilder<double>(
      valueListenable: offset,
      builder: (context, off, _) {
        final o = (1 - off / (mapH * 0.35)).clamp(0.0, 1.0);
        return Positioned.fill(
          child: IgnorePointer(
            ignoring: o < 0.3,
            child: Opacity(
              opacity: o,
              child: Stack(children: [
                Positioned(
                  top: top + 18, left: 16,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("1LAVO", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5, color: p.acc, height: 1.1)),
                    Text("LAVAGE AUTO PRO", style: TextStyle(fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.w700, color: p.mut)),
                  ]),
                ),
                Positioned(top: top + 14, right: 14, child: fab(p, Icons.menu, () => openMenu(p))),
                Positioned(top: mapH - 44 - 48, left: 14, child: fab(p, Icons.near_me_outlined, locate)),
              ]),
            ),
          ),
        );
      },
    );

    final total = (size >= 0 && svc >= 0) ? "${svcs[svc].p[size]} MAD" : "— MAD";
    final bar = Positioned(
      left: 0, right: 0, bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + mq.padding.bottom),
        decoration: BoxDecoration(color: p.sheet, borderRadius: const BorderRadius.vertical(top: Radius.circular(22)), boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 20, offset: Offset(0, -4))]),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text("Total estimé", style: TextStyle(fontSize: 11, color: p.mut)),
            Text(total, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: p.txt)),
          ]),
          const SizedBox(width: 14),
          Expanded(child: goBtn(p, "Réserver", send)),
        ]),
      ),
    );

    final doneView = Positioned.fill(
      child: Container(
        color: p.bg,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 30 + top, 18, 30),
          child: Column(children: [
            Container(width: 76, height: 76, margin: const EdgeInsets.only(top: 10, bottom: 10), alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, color: p.acc), child: const Text("✓", style: TextStyle(color: Colors.white, fontSize: 38))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text("Demande prête !", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: p.txt))),
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text("Dernière étape : appuyez sur un bouton ci-dessous pour envoyer votre demande à 1LAVO.", textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: p.mut))),
            Container(width: double.infinity, margin: const EdgeInsets.symmetric(vertical: 8), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: p.sheet, borderRadius: BorderRadius.circular(16)), child: Text(recap, style: TextStyle(fontSize: 13, height: 1.5, color: p.txt))),
            goBtn(p, "✉️ Ouvrir mon application e-mail", () => openUrl(mailto)),
            secBtn(p, "Ouvrir Gmail", () => openUrl(gmail)),
            secBtn(p, copyAdrLabel, () async {
              await Clipboard.setData(const ClipboardData(text: emailDest));
              setState(() => copyAdrLabel = "Adresse copiée ✓");
            }),
            secBtn(p, copyLabel, () async {
              await Clipboard.setData(ClipboardData(text: recap));
              setState(() => copyLabel = "Copié ✓");
            }),
            secBtn(p, "Nouvelle réservation", () {
              setState(() => done = false);
              if (scroll.hasClients) scroll.jumpTo(0);
            }),
          ]),
        ),
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: p.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: p.dark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: p.bg,
        body: DefaultTextStyle.merge(
          style: TextStyle(color: p.txt),
          child: Stack(children: [
            mapLayer,
            Positioned.fill(
              child: SingleChildScrollView(
                controller: scroll,
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(children: [SizedBox(height: mapH - 26), sheetBody]),
              ),
            ),
            topOverlay,
            if (mq.viewInsets.bottom == 0) bar,
            if (done) doneView,
          ]),
        ),
      ),
    );
  }
}
