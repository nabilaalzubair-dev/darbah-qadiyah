import 'dart:math';

import 'package:darbah_qadiyah/game/game_models.dart';

class QuestionBank {
  QuestionBank({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Creates 200 questions (5 categories x 40).
  List<GameQuestion> build200Questions() {
    final categories = QuestionCategory.values;
    final questions = <GameQuestion>[];

    final templatesByCategory = _templatesByCategory();
    for (final category in categories) {
      final templates = templatesByCategory[category] ?? const <_QuestionTemplate>[];
      for (var i = 1; i <= 40; i++) {
        // Ensure we don't repeat the exact same visible question text within the 40.
        // If we run out of curated templates, generate unique fallbacks.
        final t = templates.isEmpty
            ? _QuestionTemplate.fallbackWithIndex(category, i)
            : (i - 1 < templates.length ? templates[i - 1] : _QuestionTemplate.fallbackWithIndex(category, i));
        // Shuffle options while keeping the correctIndex consistent.
        final shuffled = _shuffleOptionsKeepingAnswer(t.options, t.correctIndex);
        questions.add(
          GameQuestion(
            id: '${category.name}-$i',
            category: category,
            difficulty: t.difficulty,
            text: t.question,
            options: shuffled.options,
            correctIndex: shuffled.correctIndex,
          ),
        );
      }
    }

    questions.shuffle(_random);

    // Pick exactly one shield question per match (later marked by controller).
    return questions;
  }

  static String categoryArabicLabel(QuestionCategory c) => switch (c) {
    QuestionCategory.islamic => 'إسلامية',
    QuestionCategory.history => 'تأريخ',
    QuestionCategory.science => 'علوم',
    QuestionCategory.geography => 'جغرافيا',
    QuestionCategory.literature => 'أدب',
  };

  Map<QuestionCategory, List<_QuestionTemplate>> _templatesByCategory() => {
    // لكل تخصص: 40 سؤال موزّعة (8 سهلة + 20 متوسطة + 12 صعبة) = 40.
    // المجموع النهائي: 200 سؤال بنسبة 20% سهلة + 50% متوسطة + 30% صعبة.
    QuestionCategory.islamic: const [
      // Easy (8)
      _QuestionTemplate('ما اسم صلاة الفجر من حيث عدد الركعات؟', ['ركعتان', 'ثلاث ركعات', 'أربع ركعات', 'خمس ركعات'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('ما السورة التي تُسمّى "أمّ الكتاب"؟', ['الفاتحة', 'الإخلاص', 'الناس', 'الكافرون'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('الوضوء شرط لصحة…', ['الصلاة', 'الزكاة', 'الصوم', 'الصدقة'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('في أي شهر هجري يكون صوم رمضان؟', ['رمضان', 'شوال', 'ذو الحجة', 'محرم'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('كم عدد أركان الإسلام؟', ['خمسة', 'أربعة', 'ستة', 'ثلاثة'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('الإحسان في الحديث المشهور هو أن تعبد الله…', ['كأنك تراه', 'لتراه', 'حتى تراه', 'كي تراه'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('ما معنى كلمة "الزكاة" لغويًا أقرب إلى…', ['النماء والطهارة', 'القوة والغلبة', 'السفر والارتحال', 'المال والربح'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('أيّ الأيام يُستحب صومها أسبوعيًا؟', ['الاثنين والخميس', 'السبت والأحد', 'الأربعاء والجمعة', 'الثلاثاء والسبت'], 0, QuestionDifficulty.easy),
      // Medium (20)
      _QuestionTemplate('ما اسم الغزوة التي عُرفت بـ "غزوة الأحزاب" أيضًا؟', ['الخندق', 'بدر', 'حنين', 'خيبر'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيّ الآتية من مصارف الزكاة المذكورة في القرآن؟', ['ابن السبيل', 'الجار القريب', 'طالب العلم فقط', 'المريض فقط'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيّ الآتية تُسمّى "السبع المثاني"؟', ['سورة الفاتحة', 'سورة البقرة', 'سورة الكهف', 'سورة الرحمن'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('من هو الصحابي الملقب بـ "ذي النورين"؟', ['عثمان بن عفان', 'علي بن أبي طالب', 'عمر بن الخطاب', 'أبو بكر الصديق'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيّ مما يلي يُعدّ من نواقض الوضوء؟', ['خروج الريح', 'لمس الثوب', 'قص الأظافر', 'تغيير المكان'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('ما اسم السورة التي بدأت بـ "تبارك"؟', ['الملك', 'القلم', 'الشورى', 'الحديد'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('في أي عام هاجر النبي ﷺ إلى المدينة؟', ['السنة 13 للبعثة', 'السنة 5 للبعثة', 'السنة 1 للبعثة', 'السنة 20 للبعثة'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيّ صلاة تُسمّى "الوتر" عادة؟', ['صلاة تُختم بركعة', 'صلاة في أول النهار', 'صلاة فرض الظهر', 'صلاة الجنازة'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('من هو أول الخلفاء الراشدين؟', ['أبو بكر الصديق', 'عمر بن الخطاب', 'عثمان بن عفان', 'علي بن أبي طالب'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيّ التالية من أسماء يوم القيامة في القرآن؟', ['يوم التغابن', 'يوم التسابق', 'يوم الرحيل', 'يوم الاستراحة'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('ما المقصود بـ "الإسراء"؟', ['انتقال النبي ﷺ ليلًا إلى بيت المقدس', 'نزول الوحي لأول مرة', 'الهجرة إلى الحبشة', 'حجة الوداع'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيّ مما يلي من الكبائر المشهورة؟', ['عقوق الوالدين', 'ترك النوم مبكرًا', 'الإكثار من المزاح', 'رفع الصوت في السوق'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('التيمم يكون عند…', ['فقد الماء أو تعذّر استعماله', 'توفر الماء بكثرة', 'وجود العطر فقط', 'القدرة على السباحة'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيّ الآتية من "العبادات المالية"؟', ['الزكاة', 'الركوع', 'السجود', 'التسبيح'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('في أي سورة وردت آية الكرسي؟', ['البقرة', 'آل عمران', 'النساء', 'المائدة'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('ما هو "النسيء" الذي ذُمّ في القرآن؟', ['تأخير حرمة الأشهر الحرم', 'إطعام المساكين', 'تعليم الصغار', 'التجارة بالحلال'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيّ مما يلي من سنن الفطرة؟', ['قص الشارب', 'تطويل الأظافر', 'ترك السواك', 'ترك الاغتسال'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('من هو الصحابي الذي أُذن له أن يؤذن للناس؟', ['بلال بن رباح', 'سلمان الفارسي', 'أبو ذر الغفاري', 'عبدالله بن مسعود'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('ما اسم صلح النبي ﷺ مع قريش الذي كان مقدمة لفتح مكة؟', ['صلح الحديبية', 'صلح الطائف', 'صلح تبوك', 'صلح بدر'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيّ العبادات يُشترط لها استقبال القبلة؟', ['الصلاة', 'الصدقة', 'قراءة القرآن', 'الذكر'], 0, QuestionDifficulty.medium),
      // Hard (12)
      _QuestionTemplate('أيُّ القراءات تُنسب إلى الإمام عاصم في أشهر الروايات؟', ['حفص', 'ورش', 'قالون', 'الدوري'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('ما اسم أمّ المؤمنين التي لُقبت بـ "ذات النطاقين"؟', ['هذا اللقب لأسماء بنت أبي بكر', 'خديجة بنت خويلد', 'حفصة بنت عمر', 'زينب بنت جحش'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيّ الآيات تُعدّ من "آيات الأحكام" المتعلقة بالمواريث؟', ['آيات سورة النساء', 'آيات سورة الكهف', 'آيات سورة يس', 'آيات سورة الفيل'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('من هو الصحابي الذي قاد المسلمين في اليرموك؟', ['خالد بن الوليد', 'عمرو بن العاص', 'سعد بن أبي وقاص', 'المثنى بن حارثة'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('في أصول الفقه: ما تعريف "العام"؟', ['لفظ يستغرق جميع ما يصلح له', 'لفظ يدل على واحد بعينه', 'لفظ لا معنى له', 'لفظ يدل على الماضي فقط'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('ما اسم "عام الرمادة"؟', ['عام مجاعة في عهد عمر', 'عام فتح مكة', 'عام الهجرة', 'عام حجة الوداع'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيّ الأحاديث يُسمّى "حديث جبريل" لشموله…', ['الإسلام والإيمان والإحسان', 'الصلاة والزكاة فقط', 'التجارة والبيع', 'الجهاد فقط'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيُّ مصطلح يعني: صرف اللفظ عن ظاهره لدليل؟', ['التأويل', 'الترجيح', 'النسخ', 'الاجتهاد'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('ما المقصود بـ "الإجماع" في أصول الفقه؟', ['اتفاق مجتهدي الأمة في عصر على حكم', 'اجتهاد عالم واحد', 'رأي العامة في المسألة', 'تجربة شخصية'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيّ سور القرآن تُسمّى "المعوذتين"؟', ['الفلق والناس', 'الإخلاص والفاتحة', 'القدر والكوثر', 'الضحى والشرح'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('في علم الحديث: ما معنى "متواتر"؟', ['رواه جمع يستحيل تواطؤهم على الكذب', 'رواه شخص واحد', 'مجهول السند', 'منقطع الإسناد'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('ما اسم المدينة التي بويع فيها النبي ﷺ بيعة العقبة؟', ['منى قرب مكة', 'الطائف', 'خيبر', 'تبوك'], 0, QuestionDifficulty.hard),
    ],

    QuestionCategory.history: const [
      // Easy (8)
      _QuestionTemplate('ما اسم أول عاصمة للدولة الأموية؟', ['دمشق', 'بغداد', 'القاهرة', 'قرطبة'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('من القائد الذي فتح الأندلس؟', ['طارق بن زياد', 'صلاح الدين', 'قطز', 'سيف الدين قطز'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('في أي مدينة تأسست الدولة العباسية بدايةً؟', ['الكوفة', 'مكة', 'المدينة', 'دمياط'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('الحروب الصليبية كانت في المقام الأول حول…', ['القدس وبلاد الشام', 'الهند والصين', 'الأندلس فقط', 'إفريقيا الجنوبية'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('من أشهر علماء بيت الحكمة في بغداد؟', ['الخوارزمي', 'أفلاطون', 'سقراط', 'ديكارت'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('سنة 1492م تُذكر غالبًا بسقوط…', ['غرناطة', 'بغداد', 'دمشق', 'القسطنطينية'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('من هو مؤسس الدولة العثمانية؟', ['عثمان بن أرطغرل', 'سليمان القانوني', 'محمد الفاتح', 'ألب أرسلان'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('المماليك اشتهروا بانتصارهم على المغول في…', ['عين جالوت', 'بدر', 'اليرموك', 'القادسية'], 0, QuestionDifficulty.easy),
      // Medium (20)
      _QuestionTemplate('أيُّ حدث أنهى رسميًا الدولة العباسية في بغداد عام 1258م؟', ['الغزو المغولي', 'الحروب الصليبية', 'الفتح العثماني', 'النهضة الأوروبية'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('من الخليفة الذي اشتهر ببناء قبة الصخرة؟', ['عبد الملك بن مروان', 'معاوية بن أبي سفيان', 'هارون الرشيد', 'المأمون'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('معركة القادسية كانت بين المسلمين و…', ['الفرس الساسانيين', 'الروم البيزنطيين', 'المغول', 'الفرنجة'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ مدينة سُمّيت "مدينة السلام" تاريخيًا؟', ['بغداد', 'المدينة المنورة', 'حلب', 'فاس'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('من القائد الذي هزم الصليبيين في حطين؟', ['صلاح الدين الأيوبي', 'نور الدين زنكي', 'بيبرس', 'طغرل بك'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ الإمبراطوريات كانت عاصمتها القسطنطينية؟', ['البيزنطية', 'الساسانية', 'الفرعونية', 'الماورية'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('طريق الحرير كان يربط أساسًا بين…', ['آسيا وأوروبا', 'أستراليا وأمريكا', 'إفريقيا وأمريكا', 'القطبين'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ اكتشاف بحري فتح طريق رأس الرجاء الصالح نحو الهند؟', ['دوران حول إفريقيا', 'حفر قناة بنما', 'فتح مضيق جبل طارق', 'اكتشاف القطب الشمالي'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('الثورة الصناعية بدأت أولًا في…', ['بريطانيا', 'اليابان', 'الهند', 'مصر'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('مؤتمر برلين (1884-1885) ارتبط بـ…', ['تقسيم إفريقيا', 'توحيد ألمانيا', 'استقلال الهند', 'إنهاء الحرب العالمية الأولى'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ حضارة قديمة ارتبطت بألواح مسمارية في بلاد الرافدين؟', ['السومرية', 'الإغريقية', 'المايا', 'الرومانية'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('محمد علي باشا ارتبط بمشروع تحديث في…', ['مصر', 'المغرب', 'الأندلس', 'الحجاز'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ حرب سُمّيت "الحرب الكبرى" قبل تسميتها عالميًا؟', ['الحرب العالمية الأولى', 'الحرب العالمية الثانية', 'حرب القرم', 'حرب فيتنام'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('سقوط القسطنطينية كان عام…', ['1453م', '1492م', '1258م', '1517م'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ دولة قادها جنكيز خان؟', ['الإمبراطورية المغولية', 'الإمبراطورية الرومانية', 'الإمبراطورية الإسبانية', 'الساسانية'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('النهضة الأوروبية ارتبطت ازدهارًا في…', ['الفنون والعلوم', 'الملاكمة', 'الزراعة فقط', 'الهجرة للقطب'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('من هو القائد الذي وحّد معظم الجزيرة العربية في القرن العشرين؟', ['الملك عبدالعزيز', 'الملك فيصل', 'سعد زغلول', 'مصطفى كمال'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ مدينة كانت مركزًا علميًا في الأندلس تُعرف بالجامع الكبير؟', ['قرطبة', 'روما', 'لندن', 'بكين'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('معركة عين جالوت كانت عام 1260م بين المماليك و…', ['المغول', 'الفرس', 'الروم', 'البرتغاليين'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('حركة "عدم الانحياز" ظهرت في سياق…', ['الحرب الباردة', 'الحروب الصليبية', 'النهضة العباسية', 'الفتوحات الأندلسية'], 0, QuestionDifficulty.medium),
      // Hard (12)
      _QuestionTemplate('أيُّ خليفة عباسي ارتبط بمحنة خلق القرآن؟', ['المأمون', 'السفاح', 'المنصور', 'المهدي'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيُّ معركة أنهت فعليًا النفوذ الأموي في الشرق؟', ['الزاب', 'القادسية', 'اليرموك', 'صفين'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('اتفاقية سايكس–بيكو (1916) ارتبطت بـ…', ['تقسيم المشرق العربي', 'توحيد إيطاليا', 'استقلال أمريكا', 'تأسيس الاتحاد الأوروبي'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('الدولة الفاطمية تأسست أولًا في…', ['المغرب العربي', 'العراق', 'اليمن', 'الأناضول'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('من هو السلطان العثماني الذي لُقب بـ "القانوني"؟', ['سليمان الأول', 'مراد الثاني', 'سليم الأول', 'بايزيد الأول'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('مدينة "طليطلة" في الأندلس اشتهرت تاريخيًا بـ…', ['حركة ترجمة كبرى', 'بناء الأهرامات', 'اختراع البارود', 'تأسيس روما'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيُّ دولة أوروبية قادت "الكشوف الجغرافية" مبكرًا عبر الأطلسي؟', ['البرتغال', 'سويسرا', 'روسيا', 'النمسا'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('معاهدة وستفاليا (1648) ارتبطت بـ…', ['نهاية حرب الثلاثين عامًا', 'نهاية الحرب العالمية الأولى', 'سقوط الأندلس', 'فتح القسطنطينية'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('حرب البوسنة في التسعينات ارتبطت بتفكك…', ['يوغوسلافيا', 'الاتحاد السوفيتي', 'الدولة العثمانية', 'الإمبراطورية الرومانية'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('الدولة الزنكية ارتبطت تاريخيًا بمدن…', ['الموصل وحلب', 'قرطبة وغرناطة', 'روما وفلورنسا', 'بغداد وسمرقند'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('في التاريخ الإسلامي: من قائد فتح عمورية المشهور؟', ['المعتصم', 'هارون الرشيد', 'المتوكل', 'الواثق'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('الحرب البيلوبونيسية كانت بين أثينا و…', ['إسبرطة', 'قرطاجة', 'روما', 'مصر'], 0, QuestionDifficulty.hard),
    ],

    QuestionCategory.science: const [
      // Easy (8)
      _QuestionTemplate('أيّ كوكب يُعرف بالكوكب الأحمر؟', ['المريخ', 'الزهرة', 'عطارد', 'نبتون'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('ما الغاز الذي تحتاجه النار لتشتعل؟', ['الأكسجين', 'الهيليوم', 'النيتروجين', 'الأرجون'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('ما وحدة قياس التيار الكهربائي؟', ['الأمبير', 'الواط', 'الفولت', 'الأوم'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('الحمض في الليمون يُسمّى غالبًا…', ['ستريك', 'لاكتيك', 'كربونيك', 'سلفوريك'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('الـDNA يوجد أساسًا داخل…', ['نواة الخلية', 'جدار الخلية', 'الميتوكوندريا فقط', 'السيتوبلازم فقط'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('ما أقرب تعريف للفيروس؟', ['عامل ممرض يحتاج خلية ليتكاثر', 'بكتيريا كبيرة', 'فطر متعدد الخلايا', 'طحلب مائي'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('أيّ حاسة ترتبط بالقوقعة في الأذن؟', ['السمع', 'الشم', 'الذوق', 'اللمس'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('أيّ طاقة تُنتجها الألواح الشمسية؟', ['كهربائية', 'نووية', 'صوتية', 'مغناطيسية'], 0, QuestionDifficulty.easy),
      // Medium (20)
      _QuestionTemplate('أيّ طبقة من الغلاف الجوي تحوي الأوزون بكثرة؟', ['الستراتوسفير', 'التروبوسفير', 'الميزوسفير', 'الإكسوسفير'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('ما اسم العملية التي تحوّل فيها النباتات الضوء لطاقة كيميائية؟', ['البناء الضوئي', 'التنفس الخلوي', 'الانقسام المتساوي', 'التخمر'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('في الفيزياء: السرعة المتجهة تختلف عن السرعة بأنها…', ['تتضمن اتجاهًا', 'تُقاس بالكيلوغرام', 'لا تتغير أبدًا', 'تساوي دائمًا صفر'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيّ مما يلي يُعدّ كوكبًا غازيًا عملاقًا؟', ['المشتري', 'الأرض', 'المريخ', 'عطارد'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('ما اسم أكبر عضو في جسم الإنسان؟', ['الجلد', 'الكبد', 'القلب', 'الرئة'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('في الكيمياء: الرقم الهيدروجيني pH أقل من 7 يعني…', ['حمضي', 'قاعدي', 'متعادل', 'معدني'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('ما اسم جهاز في الخلية مسؤول عن إنتاج الطاقة؟', ['الميتوكوندريا', 'الريبوسوم', 'الجولجي', 'الليسوسوم'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيّ جسيم دون ذري يحمل شحنة سالبة؟', ['الإلكترون', 'البروتون', 'النيوترون', 'الفوتون'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('من أمثلة "الموصلات" الكهربائية الجيدة…', ['النحاس', 'الخشب', 'الزجاج', 'المطاط'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('الموجات الراديوية تقع ضمن…', ['الطيف الكهرومغناطيسي', 'الطيف الصوتي', 'طيف الجاذبية', 'طيف الحرارة فقط'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('التسارع يعني…', ['تغير السرعة مع الزمن', 'المسافة فقط', 'الكتلة فقط', 'الزمن فقط'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيّ التالي يعدّ "حجرًا رسوبيًا"؟', ['الحجر الجيري', 'الجرانيت', 'البازلت', 'السبج'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('لماذا يطفو الجليد فوق الماء؟', ['كثافته أقل', 'كثافته أعلى', 'لأنه أدفأ', 'لأنه أغمق'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أقرب تعريف لـ "الذكاء الاصطناعي" هو…', ['محاكاة بعض قدرات التفكير بالآلة', 'برنامج رسم فقط', 'محرك كهربائي', 'ملف صوت'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('ما اسم ظاهرة انحناء الضوء حول الأجسام؟', ['الحيود', 'الاحتراق', 'التبخر', 'التسامي'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('في جسم الإنسان: البنكرياس يرتبط مباشرة بتنظيم…', ['السكر في الدم', 'الرؤية', 'السمع', 'الشعر'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيّ الكواكب يمتلك أكبر عدد معروف من الأقمار؟', ['زحل', 'عطارد', 'الزهرة', 'الأرض'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('ما العامل الأساسي الذي يحدد شدة الجاذبية بين جسمين؟', ['الكتلة والمسافة', 'اللون والحرارة', 'الرائحة والطعم', 'الضغط والصوت'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('ما اسم المقياس المستخدم لشدة الزلازل تاريخيًا (غير ريختر)؟', ['ميركالي', 'فهرنهايت', 'كالوري', 'أوم'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيّ مما يلي طاقة "كامنة" غالبًا؟', ['ماء مخزن خلف سد', 'ضوء مصباح', 'صوت مكبر', 'حرارة فرن'], 0, QuestionDifficulty.medium),
      // Hard (12)
      _QuestionTemplate('ما اسم عدد الذرات في مول واحد (تقريبًا)؟', ['عدد أفوجادرو', 'عدد فيبوناتشي', 'عدد بيرنولي', 'عدد نيوتن'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('ما اسم ظاهرة تحوّل الغاز مباشرة إلى صلب؟', ['الترسّب', 'التبخر', 'التكاثف', 'الانصهار'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيّ نوع من الإشعاع يمتلك أعلى طاقة عادةً؟', ['غاما', 'تحت الحمراء', 'الميكروويف', 'الراديو'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('في الوراثة: ما المقصود بـ "النمط الظاهري"؟', ['الصفات الملاحظة', 'ترتيب الجينات فقط', 'عدد الكروموسومات', 'نوع البروتين فقط'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيّ معادلة تصف علاقة الطاقة بكتلة الجسم؟', ['E=mc²', 'F=ma', 'V=IR', 'a²+b²=c²'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('ما اسم الحد الفاصل بين الوشاح ولب الأرض؟', ['حد جوتنبرج', 'حد موهو', 'حد دالتون', 'حد أرخميدس'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('في الكيمياء: الرابطة التي تشارك فيها الذرات إلكترونات تُسمّى…', ['تساهمية', 'أيونية', 'هيدروجينية', 'مغناطيسية'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيّ نوع من الخلايا يحمل الأكسجين في الدم؟', ['كريات الدم الحمراء', 'الصفائح الدموية', 'كريات الدم البيضاء', 'الخلايا العصبية'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('ما اسم الظاهرة التي تجعل اتجاه دوران الماء يختلف بين نصفي الكرة؟', ['تأثير كوريوليس', 'تأثير دوبلر', 'تأثير هول', 'تأثير زينر'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('في الحوسبة: ما معنى اختصار "HTTP"؟', ['بروتوكول نقل النص التشعبي', 'ترميز الصور عالي الدقة', 'نظام تشغيل محمول', 'لغة برمجة'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيّ مفهوم يشرح انتقال الحرارة في الفراغ؟', ['الإشعاع', 'الحمل', 'التوصيل', 'الاحتكاك'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('في الفيزياء الفلكية: ما اسم بقايا نجم انهار شديد الكثافة؟', ['نجم نيوتروني', 'كوكب صخري', 'مذنب', 'سديم فقط'], 0, QuestionDifficulty.hard),
    ],

    QuestionCategory.geography: const [
      // Easy (8)
      _QuestionTemplate('ما عاصمة المملكة العربية السعودية؟', ['الرياض', 'جدة', 'مكة', 'الدمام'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('أي قارة تقع فيها مصر؟', ['أفريقيا', 'أوروبا', 'أستراليا', 'أمريكا الجنوبية'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('أكبر محيط في العالم هو…', ['الهادئ', 'الأطلسي', 'الهندي', 'المتجمد الشمالي'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('أيّ مما يلي نهر؟', ['الأمازون', 'الهيمالايا', 'الصحراء الكبرى', 'القطب الجنوبي'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('أي دولة تُعرف بوجود الحرمين الشريفين؟', ['السعودية', 'المغرب', 'تركيا', 'إندونيسيا'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('أيّ مما يلي بحر بين إفريقيا وآسيا؟', ['البحر الأحمر', 'بحر قزوين', 'بحر إيجه', 'بحر الشمال'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('أيّ مدينة تُعرف غالبًا بـ "مدينة الضباب"؟', ['لندن', 'باريس', 'روما', 'مدريد'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('أكبر قارة من حيث المساحة هي…', ['آسيا', 'أفريقيا', 'أوروبا', 'أمريكا الجنوبية'], 0, QuestionDifficulty.easy),
      // Medium (20)
      _QuestionTemplate('أيُّ مضيق يفصل بين المغرب وإسبانيا؟', ['جبل طارق', 'هرمز', 'باب المندب', 'ملقا'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أعلى جبل في العالم هو…', ['إيفرست', 'كينيا', 'مون بلان', 'أكونكاغوا'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('نهر النيل يصب في…', ['البحر المتوسط', 'البحر الأحمر', 'المحيط الأطلسي', 'بحر العرب'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ دولة تُعدّ الأكبر مساحة في العالم؟', ['روسيا', 'كندا', 'الصين', 'أستراليا'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('في أي قارة تقع البرازيل؟', ['أمريكا الجنوبية', 'أمريكا الشمالية', 'أوروبا', 'أفريقيا'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيّ ظاهرة تُفسر اختلاف الفصول؟', ['ميل محور الأرض', 'بعد القمر', 'سرعة الرياح', 'ارتفاع الجبال'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('الصحراء الكبرى تقع أساسًا في…', ['شمال إفريقيا', 'شرق آسيا', 'أوروبا الشرقية', 'أمريكا الجنوبية'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ مدينة تقع على نهر السين؟', ['باريس', 'روما', 'برلين', 'فيينا'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ دولة من دول البلقان عاصمتها سراييفو؟', ['البوسنة والهرسك', 'بلغاريا', 'رومانيا', 'اليونان'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ بحر يُعرف بالملوحة العالية جدًا لوقوعه في منطقة مغلقة؟', ['البحر الميت', 'بحر العرب', 'بحر البلطيق', 'بحر المرجان'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('سلسلة جبال الأطلس توجد في…', ['المغرب العربي', 'الهند', 'تشيلي', 'كندا'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أكبر بحيرة عذبة من حيث المساحة هي…', ['سوبيريور', 'بايكال', 'فيكتوريا', 'تيتيكاكا'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('ما اسم الرياح الموسمية التي تؤثر في جنوب آسيا؟', ['المونسون', 'السموم', 'الشمال', 'النسيم البحري'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ دولة يُطلق عليها "أرض الألف بحيرة"؟', ['فنلندا', 'إسبانيا', 'المكسيك', 'مصر'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ خط طول هو المرجع الرئيسي عالميًا؟', ['غرينتش', 'الاستواء', 'المدار السرطاني', 'القطب'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ دولة عاصمتها كوالالمبور؟', ['ماليزيا', 'إندونيسيا', 'تايلاند', 'الفلبين'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أشهر بركان نشط في إيطاليا هو…', ['إتنا', 'فوجي', 'فيزوف (نابولي) فقط', 'كيليمنجارو'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ نهر يُعدّ الأطول في أوروبا؟', ['الفولغا', 'الراين', 'الدانوب', 'السين'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('السهول الفيضية تتكوّن غالبًا بسبب…', ['ترسيب الأنهار', 'حركة الصفائح فقط', 'تجمّد المحيط', 'هبوط القمر'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ دولة عاصمتها برازيليا وليست ريو؟', ['البرازيل', 'الأرجنتين', 'كولومبيا', 'بيرو'], 0, QuestionDifficulty.medium),
      // Hard (12)
      _QuestionTemplate('ما اسم التيار البحري الذي يدفئ سواحل أوروبا الغربية؟', ['تيار الخليج', 'تيار همبولت', 'تيار الكناري', 'تيار بنجويلا'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أعمق نقطة معروفة في المحيطات هي…', ['خندق ماريانا', 'خندق بيرو-تشيلي', 'خندق جاوة', 'خندق الفلبين'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيُّ دولة هي الأكبر عددًا من الجزر في العالم؟', ['السويد', 'إندونيسيا', 'اليابان', 'الفلبين'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('جبال الأورال تُعدّ حدًا تقليديًا بين…', ['أوروبا وآسيا', 'إفريقيا وأوروبا', 'أمريكا الشمالية والجنوبية', 'أستراليا وآسيا'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('ما اسم الإقليم الذي يشهد ظاهرة "الشمس منتصف الليل" صيفًا؟', ['الدائرة القطبية', 'خط الاستواء', 'مدار الجدي', 'مدار السرطان'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أشهر صحراء باردة في آسيا تُعرف بـ…', ['جوبي', 'الربع الخالي', 'أتاكاما', 'كالهاري'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيُّ بحر داخلي يحده 5 دول رئيسية ويشتهر بالغاز؟', ['بحر قزوين', 'بحر العرب', 'بحر إيجه', 'بحر البلطيق'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('ما اسم النقطة على الأرض ذات أقل ضغط جوي ثابت تقريبًا؟', ['الهضبة القطبية الجنوبية', 'قمة إيفرست', 'بحيرة فيكتوريا', 'سهل الرافدين'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيُّ ظاهرة جيولوجية تُنشئ جبالًا عند تصادم صفائح؟', ['الطيّ والرفع التكتوني', 'التعرية الريحية', 'الترسيب البحري', 'التجمد السطحي'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('ما اسم العاصمة الإدارية لجنوب أفريقيا (ليست كيب تاون)؟', ['بريتوريا', 'جوهانسبرغ', 'ديربان', 'سويتو'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيُّ دولة تُعدّ "قارة" في آن واحد؟', ['أستراليا', 'إسبانيا', 'الهند', 'المكسيك'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('نهر الكونغو يُعدّ ثاني أطول أنهار إفريقيا بعد…', ['النيل', 'النيجر', 'الزامبيزي', 'الأورانج'], 0, QuestionDifficulty.hard),
    ],

    QuestionCategory.literature: const [
      // Easy (8)
      _QuestionTemplate('من هو مؤلف "الأيام"؟', ['طه حسين', 'نجيب محفوظ', 'توفيق الحكيم', 'الرافعي'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('البيت الشعري يتكوّن عادة من…', ['صدر وعجز', 'مقدمة وخاتمة', 'عنوان وفصل', 'سطر واحد فقط'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('من هو شاعر "النيل"؟', ['حافظ إبراهيم', 'أحمد شوقي', 'المتنبي', 'البحتري'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('"كليلة ودمنة" تُنسب في العربية إلى…', ['ابن المقفع', 'الجاحظ', 'ابن خلدون', 'ابن رشد'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('أيُّ فن أدبي يعتمد على سرد الأحداث والشخصيات؟', ['الرواية', 'المعادلات', 'الخرائط', 'البرمجة'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('التشبيه يتكوّن غالبًا من…', ['مشبه ومشبه به', 'فاعل ومفعول فقط', 'جذر ووزن', 'سجع وجناس'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('من صاحب "حي بن يقظان"؟', ['ابن طفيل', 'ابن سينا', 'ابن الهيثم', 'الخليل بن أحمد'], 0, QuestionDifficulty.easy),
      _QuestionTemplate('المرادف الأقرب لكلمة "بلاغة" هو…', ['حسن التعبير', 'قوة العضلات', 'سرعة المشي', 'الضجيج'], 0, QuestionDifficulty.easy),
      // Medium (20)
      _QuestionTemplate('ما البحر الشعري الذي تكثر تفعيلته "متفاعلن"؟', ['الكامل', 'الوافر', 'الرجز', 'الخفيف'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('من هو رائد المسرح العربي الذي كتب "أهل الكهف"؟', ['توفيق الحكيم', 'نزار قباني', 'الجرجاني', 'الأصمعي'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('الجناس هو…', ['تشابه لفظين واختلاف المعنى', 'سرد طويل بلا معنى', 'تكرار الحروف فقط', 'وصف مكان حقيقي'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('"مقامات الحريري" تنتمي لفن…', ['المقامات', 'الملحمة', 'الموشح', 'الرسالة العلمية'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ شاعر عُرف بـ "أمير الشعراء"؟', ['أحمد شوقي', 'محمود درويش', 'جرير', 'عنترة'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أسلوب "الالتفات" في البلاغة يعني…', ['الانتقال بين ضمائر الخطاب', 'زيادة الحركات فقط', 'حذف النقاط', 'كسر الوزن عمدًا'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('الاستعارة هي تشبيه حُذف منه…', ['أحد الطرفين أو الأداة', 'الفاعل فقط', 'المفعول فقط', 'التنوين فقط'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ كتاب للجاحظ؟', ['البيان والتبيين', 'المعلقات', 'نهج البلاغة', 'الشعر والشعراء'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('"رسالة الغفران" تُنسب إلى…', ['أبي العلاء المعري', 'المتنبي', 'سيبويه', 'الشافعي'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('من أشهر شعراء المعلقات؟', ['امرؤ القيس', 'ابن الرومي', 'أبو تمام', 'أبو نواس'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('السجع يكثر في…', ['النثر الفني', 'المعادلات', 'الجداول', 'الأرقام'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('الطباق في البلاغة يعني الجمع بين…', ['الضدين', 'المرادفات', 'الأسماء فقط', 'الأفعال فقط'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('من هو مؤلف "العبر" و"المقدمة"؟', ['ابن خلدون', 'ابن بطوطة', 'ابن المقفع', 'الفارابي'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ مدرسة أدبية ارتبطت بالرومانسية العربية؟', ['أبولو', 'الواقعية الاشتراكية', 'الكلاسيكية اليونانية', 'السريالية الإسبانية'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('الشعر الحر يعتمد على…', ['تفعيلات لا أبيات متساوية', 'قافية واحدة دائمًا', 'بيت واحد فقط', 'نثر بلا إيقاع'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('من هو شاعر الحكمة القائل: "الرأي قبل شجاعة الشجعان"؟', ['المتنبي', 'حسان بن ثابت', 'الفرزدق', 'ابن زيدون'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('"الأغاني" كتاب موسوعي للأدب ألّفه…', ['أبو الفرج الأصفهاني', 'ابن هشام', 'الزمخشري', 'الطبري'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('أيُّ مصطلح يعني تكرار صوت أو حرف لإيقاع خاص؟', ['الجناس الصوتي', 'التضمين', 'الحذف', 'القلب المكاني'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('القصيدة العمودية تلتزم بـ…', ['وزن وقافية', 'شخصية واحدة', 'موضوع واحد فقط', 'لغة عامية دائمًا'], 0, QuestionDifficulty.medium),
      _QuestionTemplate('من هو مؤلف "دلائل الإعجاز"؟', ['عبد القاهر الجرجاني', 'ابن تيمية', 'ابن حزم', 'الطبري'], 0, QuestionDifficulty.medium),
      // Hard (12)
      _QuestionTemplate('أيُّ مصطلح نقدي يعني: دراسة النص من داخله دون سياق خارجي؟', ['البنيوية', 'التاريخانية', 'الانطباعية', 'الواقعية'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('"لامية العجم" قصيدة مشهورة لـ…', ['الطغرائي', 'المتنبي', 'جرير', 'المعري'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('في العروض: الزحاف هو…', ['تغيير يطرأ على التفعيلة', 'تغيير في المعنى فقط', 'زيادة في القافية فقط', 'حذف البيت الأخير'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيُّ كتاب يُعدّ من أقدم كتب النحو؟', ['الكتاب لسيبويه', 'الأغاني', 'العقد الفريد', 'طبقات الشعراء'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('السيميائيات تدرس…', ['العلامات والدلالات', 'النجوم والكواكب', 'العضلات', 'المحيطات'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('من هو صاحب "العقد الفريد"؟', ['ابن عبد ربه', 'ابن قتيبة', 'المبرد', 'ابن الأثير'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('"نقد الشعر" كتاب مبكر في النقد لـ…', ['قدامة بن جعفر', 'الجاحظ', 'ابن خلدون', 'الأصمعي'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('في البلاغة: الكناية تعتمد على…', ['إيحاء لازم المعنى', 'ذكر المعنى صراحة', 'حذف كل الأفعال', 'اختصار الحروف'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('من هو الشاعر الأندلسي صاحب "أضحى التنائي"؟', ['ابن زيدون', 'ابن خفاجة', 'لسان الدين بن الخطيب', 'ابن عربي'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('أيُّ مصطلح يعني جمع نصوص قصيرة حول فكرة واحدة؟', ['الأنطولوجيا', 'الطبوغرافيا', 'الأيقونية', 'الجيولوجيا'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('من أعلام مدرسة الديوان في الشعر العربي الحديث؟', ['العقاد', 'ابن الرومي', 'جرير', 'أبو نواس'], 0, QuestionDifficulty.hard),
      _QuestionTemplate('في السرد: "الراوي العليم" يعني…', ['يعرف كل ما يحدث ويشعر به الجميع', 'شخصية ثانوية فقط', 'راوٍ لا يرى شيئًا', 'راوٍ يكتب بالأرقام'], 0, QuestionDifficulty.hard),
    ],
  };

  _ShuffledOptions _shuffleOptionsKeepingAnswer(List<String> options, int correctIndex) {
    final indices = List<int>.generate(options.length, (i) => i);
    indices.shuffle(_random);
    final newOptions = <String>[];
    var newCorrectIndex = 0;
    for (var newI = 0; newI < indices.length; newI++) {
      final oldI = indices[newI];
      newOptions.add(options[oldI]);
      if (oldI == correctIndex) newCorrectIndex = newI;
    }
    return _ShuffledOptions(newOptions, newCorrectIndex);
  }
}

class _QuestionTemplate {
  const _QuestionTemplate(this.question, this.options, this.correctIndex, this.difficulty);
  final String question;
  final List<String> options;
  final int correctIndex;
  final QuestionDifficulty difficulty;

  factory _QuestionTemplate.fallbackWithIndex(QuestionCategory c, int i) {
    // Fallbacks يجب أن تكون "سؤالًا" مفهومًا بحد ذاته (لا عبارة تعليمات).
    // ولا نكرر أحرف A/B/C/D داخل النص لأن الـUI يعرضها كبادج.
    // ولا نُظهر أرقام داخل الخيارات لأن ذلك يربك اللاعبين.

    final (question, options) = switch (c) {
      QuestionCategory.islamic => (
        'أيّ مما يلي يُعدّ ركنًا من أركان الإسلام؟',
        const ['الزكاة', 'الصدق', 'برّ الوالدين', 'صلة الرحم'],
      ),
      QuestionCategory.history => (
        'أيّ مما يلي حدث تاريخي؟',
        const ['سقوط بغداد 1258م', 'اكتشاف نبتون', 'اختراع الإنترنت', 'تكوّن الأنهار'],
      ),
      QuestionCategory.science => (
        'أيّ مما يلي غازٌ ضروري للتنفس؟',
        const ['الأكسجين', 'النيتروجين', 'الهيدروجين', 'الهيليوم'],
      ),
      QuestionCategory.geography => (
        'أيّ مما يلي يُعدّ عاصمة؟',
        const ['الرياض', 'الأمازون', 'الهيمالايا', 'الأطلسي'],
      ),
      QuestionCategory.literature => (
        'أيّ مما يلي فن أدبي؟',
        const ['الرواية', 'المعادلات', 'الخرائط', 'البرمجة'],
      ),
    };

    // IMPORTANT:
    // الخيارات أعلاه مبنية بحيث يكون الجواب الصحيح دائمًا هو العنصر الأول (index 0).
    // ولتنويع مكان الإجابة الصحيحة بدون كسر صحة السؤال، نقوم بتدوير (rotate)
    // الخيارات ونُعدّل correctIndex وفقًا لذلك.
    final rotateBy = i % options.length;
    final rotated = <String>[];
    for (var k = 0; k < options.length; k++) {
      rotated.add(options[(k - rotateBy + options.length) % options.length]);
    }
    final correctIndex = rotateBy;
    return _QuestionTemplate(question, rotated, correctIndex, QuestionDifficulty.medium);
  }
}

class _ShuffledOptions {
  const _ShuffledOptions(this.options, this.correctIndex);
  final List<String> options;
  final int correctIndex;
}
