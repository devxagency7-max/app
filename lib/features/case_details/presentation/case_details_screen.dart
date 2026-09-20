import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../home/domain/case_priority.dart';
import '../../field_visits/presentation/field_visits_screen.dart';
import '../domain/case_full_details.dart';
import '../domain/case_readiness.dart';
import '../domain/sections/agricultural_holding_form.dart';
import '../domain/sections/assessed_needs_form.dart';
import '../domain/sections/basic_info_family_form.dart';
import '../domain/sections/classification_form.dart';
import '../domain/sections/financial_form.dart';
import '../domain/sections/housing_form.dart';
import '../domain/sections/initial_need_form.dart';
import '../domain/sections/opinions_form.dart';
import '../domain/sections/support_form.dart';
import '../domain/sections/utilities_equipment_form.dart';
import 'case_details_providers.dart';
import 'tabs/agricultural_holding_tab.dart';
import 'tabs/assessed_needs_tab.dart';
import 'tabs/basic_info_tab.dart';
import 'tabs/classification_tab.dart';
import 'tabs/family_members_tab.dart';
import 'tabs/financial_tab.dart';
import 'tabs/housing_tab.dart';
import 'tabs/initial_need_attachments_tab.dart';
import 'tabs/opinions_tab.dart';
import 'tabs/support_tab.dart';
import 'tabs/utilities_equipment_tab.dart';
import 'widgets/incomplete_submit_dialog.dart';
import 'widgets/tab_navigation_bar.dart';
import 'widgets/timeline_sheet.dart';

const _tabLabels = [
  'البيانات الأساسية',
  'الأفراد التابعين',
  'المرفقات',
  'السكن',
  'المرافق والتجهيزات',
  'الحيازة والأصول',
  'الدخل والمصروفات',
  'التصنيف الاجتماعي',
  'الاحتياجات المُقيَّمة',
  'الدعم',
  'الرأي',
];

/// صفحة تفاصيل الحالة الكاملة — Case Master Data مقسّمة إلى تابات منطقية
/// (Case Data Master Prompt §1-27). كل تاب قابل للتعديل مباشرة (عدا
/// المراجعة — صلاحية المراجع فقط)، وبه شريط تقدم يوضح نسبة اكتماله.
class CaseDetailsScreen extends ConsumerStatefulWidget {
  final String caseId;
  final String personName;
  final String displayId;
  final CasePriority priority;

  /// فهرس التاب المفتوح عند دخول الشاشة — تستخدمه شاشة التعارض لتوجيه
  /// المستخدم مباشرة إلى قسم "ادمج يدويًا" بدل أول تاب دائمًا.
  final int initialTabIndex;

  const CaseDetailsScreen({
    super.key,
    required this.caseId,
    required this.personName,
    required this.displayId,
    required this.priority,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<CaseDetailsScreen> createState() => _CaseDetailsScreenState();
}

class _CaseDetailsScreenState extends ConsumerState<CaseDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTabIndex = 0;

  BasicInfoFormData? _basicInfo;
  FamilyMembersFormData? _familyMembers;
  InitialNeedFormData? _initialNeed;
  HousingFormData? _housing;
  AgriculturalHoldingFormData? _agriculturalHolding;
  FinancialFormData? _financial;
  ClassificationFormData? _classification;
  AssessedNeedsFormData? _assessedNeeds;
  OpinionsFormData? _opinions;
  SupportRecommendationFormData? _support;
  UtilitiesEquipmentFormData? _utilitiesEquipment;

  /// فهارس التابات التي عدّلها المستخدم منذ آخر حفظ ناجح — الحفظ عند
  /// المغادرة يتجاهل تابًا لم يُلمَس، فلا يُضاف `enqueue` بلا داعٍ (§2.3،
  /// القاعدة ٤: الدمج ممتاز لكنه ليس بديلًا عن تفادي الإرسال أصلًا).
  final Set<int> _dirtyTabs = {};

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
    _tabController = TabController(
      length: _tabLabels.length,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
  }

  /// يحدّث بند "تكافل وكرامة" في تاب الدخل والمصروفات تلقائيًا = مجموع
  /// مبالغ تكافل وكرامة المسجلة لرب الأسرة وللأفراد التابعين (نفس أسلوب
  /// مزامنة "دخل أراضي زراعية" من تاب الحيازة الزراعية). التحديث التلقائي
  /// يكسب دائمًا: أي تعديل يدوي سابق على البند يُستبدل عند تغيّر مصدره.
  /// لو البند اتحذف من تاب الدخل، يُعاد إنشاؤه بدل ما تُفقد المزامنة بصمت
  /// (نفس سلوك مزامنة الحيازة الزراعية — [_syncAgriculturalHolding]).
  void _syncTakafulKarama() {
    if (_financial == null) return;

    final contributors = <TakafulKaramaContributor>[];
    if (_basicInfo?.takafulKarama == true &&
        _basicInfo?.takafulKaramaAmount != null) {
      contributors.add(
        TakafulKaramaContributor(
          relation: 'رب الأسرة',
          amount: _basicInfo!.takafulKaramaAmount!,
          onAmountChanged: (v) {
            setState(() {
              _basicInfo!.takafulKaramaAmount = v;
              _syncTakafulKarama();
            });
          },
        ),
      );
    }
    if (_familyMembers != null) {
      for (final member in _familyMembers!.members) {
        if (member.takafulKarama && member.takafulKaramaAmount != null) {
          contributors.add(
            TakafulKaramaContributor(
              relation: member.relation,
              amount: member.takafulKaramaAmount!,
              onAmountChanged: (v) {
                setState(() {
                  member.takafulKaramaAmount = v;
                  _syncTakafulKarama();
                });
              },
            ),
          );
        }
      }
    }

    var index = _financial!.incomeItems.indexWhere(
      (i) => i.sourceType == 'تكافل وكرامة',
    );
    if (index == -1) {
      _financial!.incomeItems.add(
        IncomeItemFormData(sourceType: 'تكافل وكرامة', personName: 'رب الأسرة'),
      );
      index = _financial!.incomeItems.length - 1;
    }

    final total = contributors.fold<double>(0, (sum, c) => sum + c.amount);
    _financial!.incomeItems[index].contributors = contributors;
    if (contributors.isNotEmpty) {
      _financial!.incomeItems[index].amount = total;
    }
  }

  /// يزامن بندي "إيجار أراضي زراعية" (مصروف) و"دخل أراضي زراعية" (دخل) مع
  /// تاب الحيازة الزراعية في الاتجاهين:
  /// - من الحيازة للدخل: أي تعديل في المساحة/النوع/المبلغ هنا يحدّث البند.
  /// - من الدخل للحيازة: تعديل يدوي على مبلغ البند نفسه (عبر
  ///   [onExternalAmountChanged]) يكتب القيمة رجوعًا في الحيازة، فيبقى مصدر
  ///   الحقيقة متسقًا مهما كانت جهة التعديل.
  /// لو البند اتحذف من تاب الدخل، يُعاد إنشاؤه بدل ما تُفقد المزامنة بصمت.
  void _syncAgriculturalHolding() {
    if (_financial == null || _agriculturalHolding == null) return;
    final holding = _agriculturalHolding!;

    // بند المصروف — إيجار أراضي زراعية
    var rentIndex = _financial!.expenseItems.indexWhere(
      (e) => e.expenseType == 'إيجار أراضي زراعية',
    );
    if (rentIndex == -1) {
      _financial!.expenseItems.add(ExpenseItemFormData(expenseType: 'إيجار أراضي زراعية'));
      rentIndex = _financial!.expenseItems.length - 1;
    }
    final rentItem = _financial!.expenseItems[rentIndex];
    rentItem.onExternalAmountChanged = (v) {
      holding.landRentAmount = v;
    };
    if (holding.hasLand && holding.landType == 'إيجار' && holding.landRentAmount != null) {
      rentItem.amount = holding.landRentAmount;
    }

    // بند الدخل — دخل أراضي زراعية (سنوي في الحيازة، شهري في الدخل)
    var incomeIndex = _financial!.incomeItems.indexWhere(
      (i) => i.sourceType == 'دخل أراضي زراعية',
    );
    if (incomeIndex == -1) {
      _financial!.incomeItems.add(
        IncomeItemFormData(sourceType: 'دخل أراضي زراعية', personName: 'رب الأسرة'),
      );
      incomeIndex = _financial!.incomeItems.length - 1;
    }
    final incomeItem = _financial!.incomeItems[incomeIndex];
    incomeItem.onExternalAmountChanged = (v) {
      holding.annualLandIncome = v == null ? null : v * 12;
    };
    if (holding.hasLand && holding.landType == 'تمليك' && holding.annualLandIncome != null) {
      incomeItem.amount = holding.annualLandIncome! / 12.0;
    }
  }

Future<void> _goToPreviousTab() async {
    if (_tabController.index <= 0) return;
    await _saveCurrentTabIfDirty();
    if (!mounted) return;
    _tabController.animateTo(_tabController.index - 1);
  }

  /// مفتاح تاب الحيازة — لازم عشان نطلب منه يعرض أخطاء التحقق عند المنع.
  final _agriTabKey = GlobalKey<AgriculturalHoldingTabState>();

  /// بوابة التحقق قبل مغادرة تاب للأمام. الرجوع للخلف مسموح دائمًا.
  /// حاليًا تاب الحيازة فقط هو المُقيَّد — بقية التابات تعبر كما كانت.
  ///
  /// **الحفظ المحلي يحدث دائمًا** حتى لو التاب غير مكتمل — هذه البوابة تمنع
  /// فقط الانتقال البصري، لا تمنع تخزين ما كتبه الأخصائي فعليًا.
  bool _canLeaveTab(int index) {
    // فهرس 5 = تاب الحيازة والأصول ضمن [_tabLabels].
    if (index != 5) return true;
    final holding = _agriculturalHolding;
    if (holding == null || holding.isComplete) return true;

    _agriTabKey.currentState?.showValidationErrors();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'أكمل الحقول المطلوبة قبل الانتقال: ${holding.missingFields.join(' — ')}',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    return false;
  }

  Future<void> _goToNextTab() async {
    if (_tabController.index >= _tabLabels.length - 1) return;
    if (!_canLeaveTab(_tabController.index)) return;
    await _saveCurrentTabIfDirty();
    if (!mounted) return;
    _tabController.animateTo(_tabController.index + 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _seedFromServerData(CaseFullDetails data) {
    _basicInfo ??= BasicInfoFormData(
      caseName: data.basicInfo.fullName.value,
      nationalId: data.basicInfo.nationalId.value,
      educationLevel: data.basicInfo.educationLevel,
      age: data.basicInfo.age,
      gender: data.basicInfo.gender,
      phone1: data.basicInfo.phone.value,
      phone2: data.basicInfo.alternatePhone,
      job: data.basicInfo.occupation,
      district: data.basicInfo.district,
      village: data.basicInfo.village,
      address: data.basicInfo.addressDescription,
    );
    _familyMembers ??= FamilyMembersFormData();
    _initialNeed ??= InitialNeedFormData(
      needType: data.initialNeed?.needType ?? '',
      description: data.initialNeed?.description,
      priorityLevel: data.initialNeed?.priorityLevel ?? '',
      details: data.initialNeed?.details,
      notes: data.initialNeed?.notes,
    );
    _housing ??= HousingFormData();
    _agriculturalHolding ??= AgriculturalHoldingFormData();
    _financial ??= FinancialFormData(
      familyMembersCount: data.financialSummary?.familyMembersCount ?? 1,
    );
    _classification ??= ClassificationFormData(
      mainClassifications: data.classification?.mainClassifications.toList(),
      subClassification: data.classification?.subClassification,
      needLevel: data.classification?.needLevel ?? '',
      priorityLevel: data.classification?.priorityLevel ?? '',
      vulnerabilityLevel: data.classification?.vulnerabilityLevel,
      notes: data.classification?.notes,
    );
    _assessedNeeds ??= AssessedNeedsFormData(
      needs: [
        for (final n in data.assessedNeeds)
          AssessedNeedFormData(
            needType: n.needType,
            category: n.category,
            description: n.description,
            priorityLevel: n.priorityLevel,
            reason: n.reason,
            source: n.source,
            status: n.status,
            notes: n.notes,
          ),
      ],
    );
    _opinions ??= OpinionsFormData();
    _support ??= SupportRecommendationFormData();
    _utilitiesEquipment ??= UtilitiesEquipmentFormData();
  }

  /// يُستدعى من كل `onChanged` لتاب — يعلّم التاب كـ "معدَّل منذ آخر حفظ".
  void _markDirty(int tabIndex) => _dirtyTabs.add(tabIndex);

  /// TODO(firebase): الحفظ يُربَط بـ Firestore. حاليًا يصفّر علامة التعديل فقط.
  Future<void> _saveCurrentTabIfDirty() async {
    _dirtyTabs.remove(_tabController.index);
  }

  Future<void> _handleSubmitForReview() async {
    final readiness = CaseReadiness(
      basicInfo: _basicInfo!,
      familyMembers: _familyMembers!,
      initialNeed: _initialNeed!,
      housing: _housing!,
      financial: _financial!,
      opinions: _opinions!,
      support: _support!,
    );

    if (!readiness.isReadyForReview) {
      final confirmed = await IncompleteSubmitDialog.show(
        context,
        readiness.missingSections,
      );
      if (!confirmed) return;
    }

    if (!mounted) return;
    // TODO: POST /api/v1/cases/{caseId}/submit-for-review — Backend Contract §37
    // عند الإرسال رغم النقص، يجب تسجيل ذلك صراحة في Audit Trail
    // ("تم الإرسال رغم نقص البيانات") — استثناء بموافقة صاحب المنتج.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال الحالة للمراجع (Mock)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(caseDetailsProvider(widget.caseId));

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.personName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                widget.displayId,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FieldVisitsScreen(
                      caseId: widget.caseId,
                      personName: widget.personName,
                    ),
                  ),
                ),
                icon: const Icon(Icons.location_on_outlined, size: 16),
                label: const Text(
                  'الزيارات',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: detailsAsync.maybeWhen(
                data: (data) => TextButton.icon(
                  onPressed: () =>
                      TimelineSheet.show(context, data.timeline),
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text(
                    'السجل',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            labelStyle: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
            tabAlignment: TabAlignment.start,
            tabs: [for (final label in _tabLabels) Tab(text: label)],
          ),
        ),
        body: detailsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _DetailsErrorState(),
          data: (data) {
            _seedFromServerData(data);
            _syncTakafulKarama();
            _syncAgriculturalHolding();

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) async {
                if (didPop) return;
                await _saveCurrentTabIfDirty();
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 76),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        BasicInfoTab(
                          initialData: _basicInfo!,
                          onChanged: (v) => setState(() {
                            _basicInfo = v;
                            _markDirty(0);
                            _syncTakafulKarama();
                          }),
                        ),
                        FamilyMembersTab(
                          initialData: _familyMembers!,
                          onChanged: (v) => setState(() {
                            _familyMembers = v;
                            _markDirty(1);
                            _syncTakafulKarama();
                          }),
                        ),
                        InitialNeedAttachmentsTab(
                          caseId: widget.caseId,
                          initialData: _initialNeed!,
                          onChanged: (v) => setState(() {
                            _initialNeed = v;
                            _markDirty(2);
                          }),
                        ),
                        HousingTab(
                          initialData: _housing!,
                          onChanged: (v) => setState(() {
                            _housing = v;
                            _markDirty(3);
                          }),
                        ),
                        UtilitiesEquipmentTab(
                          initialData: _utilitiesEquipment!,
                          onChanged: (v) => setState(() {
                            _utilitiesEquipment = v;
                            _markDirty(4);
                          }),
                        ),
                        AgriculturalHoldingTab(
                          key: _agriTabKey,
                          initialData: _agriculturalHolding!,
                          onChanged: (v) => setState(() {
                            _agriculturalHolding = v;
                            _markDirty(5);
                            _syncAgriculturalHolding();
                          }),
                        ),
                        FinancialTab(
                          initialData: _financial!,
                          onChanged: (v) => setState(() {
                            _financial = v;
                            _markDirty(6);
                            _syncAgriculturalHolding();
                          }),
                        ),
                        ClassificationTab(
                          initialData: _classification!,
                          onChanged: (v) => setState(() {
                            _classification = v;
                            _markDirty(7);
                          }),
                        ),
                        AssessedNeedsTab(
                          initialData: _assessedNeeds!,
                          onChanged: (v) => setState(() {
                            _assessedNeeds = v;
                            _markDirty(8);
                          }),
                        ),
                        SupportTab(
                          initialData: _support!,
                          onChanged: (v) => setState(() {
                            _support = v;
                            _markDirty(9);
                          }),
                          approved: data.approvedSupport,
                        ),
                        OpinionsTab(
                          initialData: _opinions!,
                          onChanged: (v) => setState(() {
                            _opinions = v;
                            _markDirty(10);
                          }),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: TabNavigationBar(
                      isFirstTab: _currentTabIndex == 0,
                      isLastTab: _currentTabIndex == _tabLabels.length - 1,
                      onPrevious: _goToPreviousTab,
                      onNext: _goToNextTab,
                      onSubmit: _handleSubmitForReview,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DetailsErrorState extends StatelessWidget {
  const _DetailsErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          'تعذر تحميل بيانات الحالة. يرجى المحاولة مرة أخرى.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.danger,
          ),
        ),
      ),
    );
  }
}
