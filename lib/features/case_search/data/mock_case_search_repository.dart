import '../../home/domain/case_priority.dart';
import '../domain/case_search_filter.dart';
import '../domain/case_search_repository.dart';
import '../domain/case_search_result.dart';

/// Mock Data Source — يحاكي بحث Server-side متعدد المعايير في كل حالات النظام.
class MockCaseSearchRepository implements CaseSearchRepository {
  static final List<CaseSearchResult> _allCases = [
    CaseSearchResult(
      id: 'case_1024',
      displayId: '#1024',
      personName: 'أحمد محمد السيد',
      nationalId: '29810152401234',
      village: 'قرية بني عدي',
      charity: 'جمعية رسالة للأعمال الخيرية',
      phone: '01012345678',
      registeredAt: DateTime(2026, 8, 10),
      statusLabel: 'قيد البحث الاجتماعي',
      priority: CasePriority.urgent,
      assignedWorkerName: 'محمد أحمد',
      isAssignedToCurrentWorker: true,
    ),
    CaseSearchResult(
      id: 'case_1031',
      displayId: '#1031',
      personName: 'سارة حسن علي',
      nationalId: '29505202405678',
      village: 'قرية الروضة',
      charity: 'مؤسسة مصر الخير',
      phone: '01123456789',
      registeredAt: DateTime(2026, 8, 15),
      statusLabel: 'مرتجعة من المراجع',
      priority: CasePriority.high,
      assignedWorkerName: 'محمد أحمد',
      isAssignedToCurrentWorker: true,
    ),
    CaseSearchResult(
      id: 'case_2011',
      displayId: '#2011',
      personName: 'حسن إبراهيم عبدالله',
      nationalId: '28912012404411',
      village: 'قرية الشيخ فضل',
      charity: 'جمعية الأورمان',
      phone: '01234567890',
      registeredAt: DateTime(2026, 7, 22),
      statusLabel: 'قيد البحث الاجتماعي',
      priority: CasePriority.medium,
      assignedWorkerName: 'أحمد محمود',
      isAssignedToCurrentWorker: false,
    ),
    CaseSearchResult(
      id: 'case_2033',
      displayId: '#2033',
      personName: 'منى عبدالعزيز السيد',
      nationalId: '29208102409021',
      village: 'قرية بني عدي',
      charity: 'بنك الطعام المصري',
      phone: '01512349876',
      registeredAt: DateTime(2026, 8, 18),
      statusLabel: 'جاهزة للإسناد',
      priority: CasePriority.low,
      assignedWorkerName: null,
      isAssignedToCurrentWorker: false,
    ),
    CaseSearchResult(
      id: 'case_2045',
      displayId: '#2045',
      personName: 'محمود أحمد عثمان',
      nationalId: '28703142407788',
      village: 'قرية الروضة',
      charity: 'جمعية رسالة للأعمال الخيرية',
      phone: '01098765432',
      registeredAt: DateTime(2026, 8, 20),
      statusLabel: 'قيد البحث الاجتماعي',
      priority: CasePriority.urgent,
      assignedWorkerName: 'محمد أحمد',
      isAssignedToCurrentWorker: true,
    ),
  ];

  @override
  Future<List<CaseSearchResult>> search(String query, {CaseSearchFilter? filter}) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final trimmedQuery = query.trim().toLowerCase();

    return _allCases.where((c) {
      // 1. General query match (if any)
      if (trimmedQuery.isNotEmpty) {
        final matchesQuery = c.personName.toLowerCase().contains(trimmedQuery) ||
            c.displayId.toLowerCase().contains(trimmedQuery) ||
            (c.nationalId?.contains(trimmedQuery) ?? false) ||
            (c.village?.toLowerCase().contains(trimmedQuery) ?? false) ||
            (c.charity?.toLowerCase().contains(trimmedQuery) ?? false) ||
            (c.phone?.contains(trimmedQuery) ?? false);
        if (!matchesQuery) return false;
      }

      // 2. Specific filter criteria match (if provided)
      if (filter != null) {
        if (filter.name.trim().isNotEmpty &&
            !c.personName.toLowerCase().contains(filter.name.trim().toLowerCase())) {
          return false;
        }
        if (filter.nationalId.trim().isNotEmpty &&
            !(c.nationalId?.contains(filter.nationalId.trim()) ?? false)) {
          return false;
        }
        if (filter.charity.trim().isNotEmpty &&
            !(c.charity?.toLowerCase().contains(filter.charity.trim().toLowerCase()) ?? false)) {
          return false;
        }
        if (filter.region.trim().isNotEmpty &&
            !(c.village?.toLowerCase().contains(filter.region.trim().toLowerCase()) ?? false)) {
          return false;
        }
        if (filter.phone.trim().isNotEmpty &&
            !(c.phone?.contains(filter.phone.trim()) ?? false)) {
          return false;
        }
        if (filter.date != null && c.registeredAt != null) {
          final isSameDay = c.registeredAt!.year == filter.date!.year &&
              c.registeredAt!.month == filter.date!.month &&
              c.registeredAt!.day == filter.date!.day;
          if (!isSameDay) return false;
        }
      }

      return true;
    }).toList();
  }
}
