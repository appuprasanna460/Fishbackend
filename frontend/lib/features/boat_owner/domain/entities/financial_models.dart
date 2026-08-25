class FinancialDashboardData {
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final double profitMargin;

  final int totalVoyages;
  final int completed;
  final int active;
  final int cancelled;
  final int planned;

  final List<ChartDataPoint> chartData;
  final TopProfitVoyage? topProfitVoyage;
  final TopExpenseCategory? topExpenseCategory;
  final List<RecentVoyageItem> recentVoyages;

  FinancialDashboardData({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.profitMargin,
    required this.totalVoyages,
    required this.completed,
    required this.active,
    required this.cancelled,
    required this.planned,
    required this.chartData,
    this.topProfitVoyage,
    this.topExpenseCategory,
    required this.recentVoyages,
  });

  factory FinancialDashboardData.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final stats = json['voyageStats'] as Map<String, dynamic>? ?? {};
    
    final chartList = json['chartData'] as List? ?? [];
    final parsedChart = chartList.map((e) => ChartDataPoint.fromJson(e)).toList();

    final recentList = json['recentVoyages'] as List? ?? [];
    final parsedRecent = recentList.map((e) => RecentVoyageItem.fromJson(e)).toList();

    TopProfitVoyage? topProf;
    if (json['topProfitVoyage'] != null) {
      topProf = TopProfitVoyage.fromJson(json['topProfitVoyage']);
    }

    TopExpenseCategory? topExp;
    if (json['topExpenseCategory'] != null) {
      topExp = TopExpenseCategory.fromJson(json['topExpenseCategory']);
    }

    return FinancialDashboardData(
      totalIncome: (summary['totalIncome'] ?? 0).toDouble(),
      totalExpenses: (summary['totalExpenses'] ?? 0).toDouble(),
      netProfit: (summary['netProfit'] ?? 0).toDouble(),
      profitMargin: (summary['profitMargin'] ?? 0).toDouble(),
      totalVoyages: stats['total'] ?? 0,
      completed: stats['completed'] ?? 0,
      active: stats['active'] ?? 0,
      cancelled: stats['cancelled'] ?? 0,
      planned: stats['planned'] ?? 0,
      chartData: parsedChart,
      topProfitVoyage: topProf,
      topExpenseCategory: topExp,
      recentVoyages: parsedRecent,
    );
  }
}

class ChartDataPoint {
  final String date;
  final double income;
  final double expenses;
  final double profit;

  ChartDataPoint({
    required this.date,
    required this.income,
    required this.expenses,
    required this.profit,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      date: json['date'] ?? '',
      income: (json['income'] ?? 0).toDouble(),
      expenses: (json['expenses'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
    );
  }
}

class TopProfitVoyage {
  final String id;
  final String voyageNo;
  final double profit;

  TopProfitVoyage({
    required this.id,
    required this.voyageNo,
    required this.profit,
  });

  factory TopProfitVoyage.fromJson(Map<String, dynamic> json) {
    return TopProfitVoyage(
      id: json['id'] ?? '',
      voyageNo: json['voyageNo'] ?? '',
      profit: (json['profit'] ?? 0).toDouble(),
    );
  }
}

class TopExpenseCategory {
  final String category;
  final double amount;

  TopExpenseCategory({
    required this.category,
    required this.amount,
  });

  factory TopExpenseCategory.fromJson(Map<String, dynamic> json) {
    return TopExpenseCategory(
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class RecentVoyageItem {
  final String id;
  final String voyageNo;
  final String date;
  final double income;
  final double expenses;
  final double profit;
  final String status;

  RecentVoyageItem({
    required this.id,
    required this.voyageNo,
    required this.date,
    required this.income,
    required this.expenses,
    required this.profit,
    required this.status,
  });

  factory RecentVoyageItem.fromJson(Map<String, dynamic> json) {
    return RecentVoyageItem(
      id: json['id'] ?? '',
      voyageNo: json['voyageNo'] ?? '',
      date: json['date'] ?? '',
      income: (json['income'] ?? 0).toDouble(),
      expenses: (json['expenses'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }
}

class VoyagePLListItem {
  final String id;
  final String voyageNo;
  final String boatName;
  final String dateRange;
  final double income;
  final double expenses;
  final double profit;
  final double profitMargin;
  final String status;

  VoyagePLListItem({
    required this.id,
    required this.voyageNo,
    required this.boatName,
    required this.dateRange,
    required this.income,
    required this.expenses,
    required this.profit,
    required this.profitMargin,
    required this.status,
  });

  factory VoyagePLListItem.fromJson(Map<String, dynamic> json) {
    return VoyagePLListItem(
      id: json['id'] ?? '',
      voyageNo: json['voyageNo'] ?? '',
      boatName: json['boatName'] ?? '',
      dateRange: json['dateRange'] ?? '',
      income: (json['income'] ?? 0).toDouble(),
      expenses: (json['expenses'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
      profitMargin: (json['profitMargin'] ?? 0).toDouble(),
      status: json['status'] ?? '',
    );
  }
}

class VoyagePLSummaryData {
  final VoyagePLMetadata voyage;
  final VoyagePLTotals summary;
  final List<VoyageIncomeItem> catchIncome;
  final List<VoyageOtherIncomeItem> otherIncome;
  final List<VoyageExpenseItem> expenses;
  final List<CrewSettlementItem> crew;

  VoyagePLSummaryData({
    required this.voyage,
    required this.summary,
    required this.catchIncome,
    required this.otherIncome,
    required this.expenses,
    required this.crew,
  });

  factory VoyagePLSummaryData.fromJson(Map<String, dynamic> json) {
    final vMeta = VoyagePLMetadata.fromJson(json['voyage'] ?? {});
    final vTotals = VoyagePLTotals.fromJson(json['summary'] ?? {});
    
    final incObj = json['income'] as Map<String, dynamic>? ?? {};
    final catchList = incObj['catchIncome'] as List? ?? [];
    final otherList = incObj['otherIncome'] as List? ?? [];

    final parsedCatch = catchList.map((e) => VoyageIncomeItem.fromJson(e)).toList();
    final parsedOther = otherList.map((e) => VoyageOtherIncomeItem.fromJson(e)).toList();

    final expList = json['expenses'] as List? ?? [];
    final parsedExp = expList.map((e) => VoyageExpenseItem.fromJson(e)).toList();

    final crewList = json['crew'] as List? ?? [];
    final parsedCrew = crewList.map((e) => CrewSettlementItem.fromJson(e)).toList();

    return VoyagePLSummaryData(
      voyage: vMeta,
      summary: vTotals,
      catchIncome: parsedCatch,
      otherIncome: parsedOther,
      expenses: parsedExp,
      crew: parsedCrew,
    );
  }
}

class VoyagePLMetadata {
  final String id;
  final String voyageNo;
  final String vesselName;
  final String vesselNumber;
  final String captainName;
  final String departureDate;
  final String departureTime;
  final String? arrivalDate;
  final String status;
  final int durationDays;

  VoyagePLMetadata({
    required this.id,
    required this.voyageNo,
    required this.vesselName,
    required this.vesselNumber,
    required this.captainName,
    required this.departureDate,
    required this.departureTime,
    this.arrivalDate,
    required this.status,
    required this.durationDays,
  });

  factory VoyagePLMetadata.fromJson(Map<String, dynamic> json) {
    return VoyagePLMetadata(
      id: json['id'] ?? '',
      voyageNo: json['voyageNo'] ?? '',
      vesselName: json['vesselName'] ?? '',
      vesselNumber: json['vesselNumber'] ?? '',
      captainName: json['captainName'] ?? '',
      departureDate: json['departureDate'] ?? '',
      departureTime: json['departureTime'] ?? '',
      arrivalDate: json['arrivalDate'],
      status: json['status'] ?? '',
      durationDays: json['durationDays'] ?? 0,
    );
  }
}

class VoyagePLTotals {
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final double profitMargin;
  final double voyageExpensesTotal;
  final double crewSettlementTotal;

  VoyagePLTotals({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.profitMargin,
    required this.voyageExpensesTotal,
    required this.crewSettlementTotal,
  });

  factory VoyagePLTotals.fromJson(Map<String, dynamic> json) {
    return VoyagePLTotals(
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
      netProfit: (json['netProfit'] ?? 0).toDouble(),
      profitMargin: (json['profitMargin'] ?? 0).toDouble(),
      voyageExpensesTotal: (json['voyageExpensesTotal'] ?? 0).toDouble(),
      crewSettlementTotal: (json['crewSettlementTotal'] ?? 0).toDouble(),
    );
  }
}

class VoyageIncomeItem {
  final String speciesName;
  final double quantity;
  final String unit;
  final double rate;
  final double amount;

  VoyageIncomeItem({
    required this.speciesName,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.amount,
  });

  factory VoyageIncomeItem.fromJson(Map<String, dynamic> json) {
    return VoyageIncomeItem(
      speciesName: json['speciesName'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'kg',
      rate: (json['rate'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speciesName': speciesName,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'amount': amount,
    };
  }
}

class VoyageOtherIncomeItem {
  final String? id;
  final String? voyageId;
  final String incomeName;
  final double amount;

  VoyageOtherIncomeItem({
    this.id,
    this.voyageId,
    required this.incomeName,
    required this.amount,
  });

  factory VoyageOtherIncomeItem.fromJson(Map<String, dynamic> json) {
    return VoyageOtherIncomeItem(
      id: json['_id'],
      voyageId: json['voyageId'],
      incomeName: json['incomeName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class VoyageExpenseItem {
  final String? id;
  final String expenseName;
  final double quantity;
  final String unit;
  final double rate;
  final double amount;
  final bool isCustom;

  VoyageExpenseItem({
    this.id,
    required this.expenseName,
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.amount,
    required this.isCustom,
  });

  factory VoyageExpenseItem.fromJson(Map<String, dynamic> json) {
    return VoyageExpenseItem(
      id: json['_id'],
      expenseName: json['expenseName'] ?? '',
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? '',
      rate: (json['rate'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      isCustom: json['isCustom'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'expenseName': expenseName,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
      'amount': amount,
      'isCustom': isCustom,
    };
  }
}

class CrewSettlementItem {
  final String crewMemberId;
  final String crewMemberName;
  final String role;
  final double advance;
  final bool paid;

  CrewSettlementItem({
    required this.crewMemberId,
    required this.crewMemberName,
    required this.role,
    required this.advance,
    required this.paid,
  });

  factory CrewSettlementItem.fromJson(Map<String, dynamic> json) {
    return CrewSettlementItem(
      crewMemberId: json['crewMemberId'] ?? '',
      crewMemberName: json['crewMemberName'] ?? '',
      role: json['role'] ?? 'Crew',
      advance: (json['advance'] ?? 0).toDouble(),
      paid: json['paid'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crewMemberId': crewMemberId,
      'crewMemberName': crewMemberName,
      'role': role,
      'advance': advance,
      'paid': paid,
    };
  }
}
