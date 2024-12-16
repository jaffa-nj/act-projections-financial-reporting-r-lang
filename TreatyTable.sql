WITH FixProgramYears AS
(
    SELECT [ID],
        [ProgramID],
        [StartDate] = IIF([StartDate] < [EndDate], [StartDate], [EndDate]),
        [EndDate] = IIF([StartDate] < [EndDate], [EndDate], [StartDate]),
        [TotalGWP],
        [GWP],
        [WPMonths],
        [ColWPMonths],
        [ULAEGWPorGEP],
        [ULAE],
        [ReinsBrokPerc],
        [SchedFCollatMult],
        [UnearnedPremResFactor],
        [ArrearsForward],
        [PostFreqAB],
        [MinCedComm],
        [ProvCedComm],
        [MaxCedComm],
        [MinLossRatio],
        [ProvLossRatioPerc],
        [MaxLossRatio]
    FROM [dbo].[ProgramYear]
)
, CleanUpData AS
(
    SELECT
        [ConcatenatedKey] = 
            UPPER(
                FORMATMESSAGE(
                    '%s_%s_%s_%s',
                    CASE
                        WHEN p.[Name] = 'LP RISK TRISURA' THEN 'LPRISK'
                        WHEN p.[Name] = 'PROGRAM BROKERAGE CORP' THEN 'PBC'
                        WHEN p.[Name] LIKE 'REDSTONE%' THEN 'REDSTONE'
                        WHEN p.[Name] = 'TRADESMAN HAB GL' THEN 'TRADESMAN HAB'
                        WHEN p.[Name] LIKE 'WHITEHILL%' THEN 'WHITEHILL(SUTTON)'
                        ELSE p.[Name]
                    END,
                    COALESCE(jr.[PrimaryLOB], 'unknown'),
                    CONVERT(nvarchar(6), jr.[EffectiveDate], 112),
                    'A'
                )
            ), -- lob.[Name], [StartDate]
        [StatusID] = p.[StatusID],
        [Status] = s.[Name],
        [ProgramID] = p.[ID],
        [Name] = p.[Name],
        [ProgramYearID] = py.[ID],
        [EffectiveDate] = jr.[EffectiveDate], --py.[StartDate], -- PY Table looks WRONG
        [ExpirationDate] = jr.[ExpirationDate], -- py.[EndDate], -- PY Table looks WRONG
        [Panel] = jr.[Panel], -- Can we get this added? Is it already available?
        [Carrier] = c.[Name],
        [PrimaryLOB] = jr.[PrimaryLOB], -- lob.[Name], -- LOB table looks WRONG
        [SecondaryLOB] = jr.[SecondaryLOB], -- Can we get this added? Is it already available?
        [CarrierRetention] = jr.[CarrierRetention], -- Can we get this added? Is it already available?
        [States] = jr.[States], -- Can we get this added? Is it already available?
        [PolicyLossLimitAggregateCap] = jr.[PolicyLossLimitAggregateCap], -- Can we get this added? Is it already available?
        [PolicyLossLimitCapClarification] = jr.[PolicyLossLimitCapClarficiation], -- Can we get this added? Is it already available?
        [PolicyLossLimitOccurrenceCap] = jr.[PolicyLossLimitOccurrenceCap], -- Can we get this added? Is it already available?
        [PolicyLossLimitPDOccurrenceCap] = jr.[PolicyLossLimitPDOccurrenceCap], -- Can we get this added? Is it already available?
        [RAvLOD] = b.[Name], --jr.[RAvLOD],
        [TotalSubjectPremium] = jr.[TotalSubjectPremium], -- py.[TotalGWP], -- PY Table looks WRONG
        [TargetParticipation] = jr.[TargetParticipation], -- py.[GWP], -- PY Table looks WRONG
        [TargetParticipationPercentage] = jr.[TargetParticipationPercentage], --py.[GWP] / py.[TotalGWP], -- Issues with prior two columns
        [AssumedPolicyLengthMonths] = py.[ColWPMonths], -- [WPMonths], jr.[AssumedPolicyLengthMonths],
        --[ULAEGWPorGEP], [ULAEFlag], -- Do we need this?
        [ULAEOutsideCedingCommission] = COALESCE(jr.[ULAEOutsideCedingCommission], NULLIF(py.[ULAE], 0)),
        [ULAETreatmentInsidevOutside] = jr.[ULAETreatmentInsidevOutside], --Can we get this added? Is it already available?
        [ULAETreatementAtActual] = jr.[ULAETreatementAtActual], --Can we get this added? Is it already available?
        [ULAETreatmentPartOfLoss] = jr.[ULAETreatmentPartOfLoss], --Can we get this added? Is it already available?
        [ALAE] = jr.[ALAE], --Can we get this added? Is it already available?
        [ALAETreatmentCapped] = jr.[ALAETreatmentCapped], --Can we get this added? Is it already available?
        [ALAETreatmentAtActual] = jr.[ALAETreatmentAtActual], --Can we get this added? Is it already available?
        [Admitted] = jr.[Admitted],  -- Can we get this added? Is it already available?
        [ES] = jr.[ES],  -- Can we get this added? Is it already available?
        [InheritedUEPROutsideParticipation] = jr.[InheritedUEPROutsideParticipation], --Can we get this added? Is it already available?
        [KeyLimits] = jr.[KeyLimits], -- Can we get this added? Is it already available?
        [ULAEorALAE] = jr.[ULAEorALAE], -- Can we get this added? Is it already available?
        [ReinsuranceBrokerCommission] = py.[ReinsBrokPerc], -- jr.[ReinsuranceBrokerCommission], -- Verified to match
        [SeparateExpenses] = jr.[SeparateExpenses], -- Can we get this added? Is it already available?
        -- how can we get frequency and arrears info?
        [CollateralTerms] = FORMATMESSAGE('%s Sch. F%s%s UEPR', FORMAT([SchedFCollatMult], 'P'), CHAR(10), FORMAT([UnearnedPremResFactor], 'P')), -- % of Sch F and UEPR; frequency and arrears
        --jr.[CollateralTerms],
        [ScheduleFMultiple] = py.[SchedFCollatMult], -- jr.[ScheduleFMultiple],  -- In most cases, it looks like JR table is wrong
        [UEPRMultiple] = jr.[UEPRMultiple], --py.[UnearnedPremResFactor], -- PY Table looks wrong
        -- This field needs a better name; how do we determine if modified or not?
        [CollateralTerms_1] = jr.[CollateralTerms_1], --IIF(py.[ArrearsForward] = 'A', 'Arrears', ''), -- Arrears or Arrears Modified; PY looks wrong
        [PostingFrequency] = jr.[PostingFrequency], -- py.[PostFreqAB], -- Using JR value for consistency
        -- Why do we have duplicate fields?
        [CommissionNotes] = jr.[CommissionNotes], -- Can we get this added? Is it already available?
        -- [FlatCommission] = IIF(COALESCE([MinCedComm],0) = COALESCE([ProvCedComm],0) AND COALESCE([MinCedComm],0) = COALESCE([MaxCedComm],0), [MinCedComm], NULL),
        [FlatCommission] = IIF(COALESCE(jr.[MinimumCedingCommission],0) = COALESCE(jr.[ProvisionalCedingCommission],0) AND COALESCE(jr.[MinimumCedingCommission],0) = COALESCE([MaximumCedingCommission],0), jr.[MinimumCedingCommission], NULL),
        [MinimumCedingCommission] = jr.[MinimumCedingCommission], -- py.[MinCedComm], -- Using JR for consistency
        [MinimumCommission] = jr.[MinimumCommission], -- py.[MinCedComm], -- Using JR for consistency
        [ProvisionalCedingCommission] = jr.[ProvisionalCedingCommission], -- py.[ProvCedComm], -- Using JR for consistency
        [ProvisionalCommission] = jr.[ProvisionalCommission], -- py.[ProvCedComm],  -- Using JR for consistency
        [MaximumCedingCommission] = jr.[MaximumCedingCommission], -- py.[MaxCedComm], -- Using JR for consistency
        [MaximumCommission] = jr.[MaximumCommission], -- py.[MaxCedComm], -- Using JR for consistency
        [MinimumCedingCommissionLLAERatio] = jr.[MinimumCedingCommissionLLAERatio], -- py.[MinLossRatio], -- Using JR for consistency
        [MinimumLossRatio] = jr.[MinimumLossRatio], -- py.[MinLossRatio], -- Using JR for consistency
        [ProvisionalCedingCommissionLLAERatio] = jr.[ProvisionalCedingCommissionLLAERatio], --py.[ProvLossRatioPerc], -- Using JR for consistency
        [ProvisionalLossRatio] = jr.[ProvisionalLossRatio], -- py.[ProvLossRatioPerc], -- Using JR for consistency
        [MaximumCedingCommissionLLAERatio] = jr.[MaximumCedingCommissionLLAERatio], -- py.[MaxLossRatio], -- Using JR for consistency
        [MaximumLossRatio] = jr.[MaximumLossRatio], -- py.[MaxLossRatio], -- Using JR for consistency
        [LossRatioCap] = jr.[LossRatioCap], -- Can we get this added? Is it already available?
        [OccurenceCap] = jr.[OccurenceCap], -- Can we get this added? Is it already available?
        -- Why do we have duplicate fields?
        [CorridorStart] = jr.[CorridorStart], -- Can we get this added? Is it already available?
        [LLAECorridorAttachmentLR] = jr.[LLAECorridorAttachmentLR], -- Can we get this added? Is it already available?
        [CorridorEnd] = jr.[CorridorEnd], -- Can we get this added? Is it already available?
        [LLAECorridorEndLR] = jr.[LLAECorridorEndLR], -- Can we get this added? Is it already available?
        [LLAECorridorRetained] = jr.[LLAECorridorRetained], -- Can we get this added? Is it already available?
        -- These come from our team
        [EstimatedPayoutDuration] = jr.[EstimatedPayoutDuration],
        [Suffix] = jr.[Suffix], --Alpha indicator for treaty differentiation (mostly years)
        [Contact] = jr.[Contact], -- This should be in CRM DB
        [Differentiator] = jr.[Differentiator], --comments from UW on what makes this ceding co stand out
        [Narrative] = jr.[Narrative], --recommendation from UW
        [Actuary] = jr.[Actuary:], -- is this the breakeven lalae?
        [ActuarialComment] = jr.[ActuarialComment],
        [ActuarialAuthor] = jr.[ActuarialAuthor],
        [PriorNoImprovementCombinedRatio] = jr.[PriorNoImprovementCombinedRatio],
        [PriorHalfImprovementCombinedRatio] = jr.[PriorHalfImprovementCombinedRatio],
        [IndustryCombinedRatio] = jr.[IndustryCombinedRatio],
        [PriorBreakevenLALAERatio] = jr.[PriorBreakevenLALAERatio],
        [MiscellaneousNotes] = jr.[MiscellaneousNotes],
        [PriorNoImprovementGrossLALAERatio] = jr.[PriorNoImprovementGrossLALAERatio],
        [PriorHalfImprovementGrossLALAERatio] = jr.[PriorHalfImprovementGrossLALAERatio],
        [ActuarialAnalysisNote] = jr.[ActuarialAnalysisNote],
        [ActuarialViewpoint] = jr.[ActuarialViewpoint],
        [PriorNoImprovmentNetLALAERatio] = jr.[PriorNoImprovmentNetLALAERatio],
        [PriorHalfImprovmentNetLALAERatio] = jr.[PriorHalfImprovmentNetLALAERatio]
    --SELECT *
    FROM [dbo].[Program] p 
        INNER JOIN [dbo].[ProgramYear] py ON p.[ID] = py.[ProgramID] -- [FixProgramYears]
        INNER JOIN [dbo].[refStatus] s on p.[StatusID] = s.[ID]
        INNER JOIN [dbo].[refBasis] b on p.[BasisID] = b.[ID]
        -- Why do these require a left join?
        LEFT JOIN [dbo].[ProgramLOB] plob ON p.[ID] = plob.[ProgramID] -- Missing G1001??
        LEFT JOIN [dbo].[refCarrier] c ON p.[CarrierID] = c.[ID]
        LEFT JOIN [dbo].[refLOB] lob ON plob.[LOBID] = lob.[ID]
        -- This one is temporary until all data in this table is available elsewhere
        INNER JOIN [dbo].[JaffaReference] jr ON p.[ID] = jr.[ProgramID] AND py.[ID] = jr.[ProgramYearID] --36
        -- Program 52 does not have an correct key for ProgramYears???
)
SELECT
    [ConcatenatedKey] = [ConcatenatedKey],
    [StatusID] = [StatusID],
    [Status] = [Status],
    [ProgramID] = MAX([ProgramID]),
    [Name] = MAX([Name]),
    [ProgramYearID] = MAX([ProgramYearID]),
    [EffectiveDate] = [EffectiveDate],
    [ExpirationDate] = [ExpirationDate],
    [Panel] = [Panel],
    [Carrier] = [Carrier],
    [PrimaryLOB] = [PrimaryLOB],
    [SecondaryLOB] = [SecondaryLOB],
    [CarrierRetention] = SUM([CarrierRetention]),
    [States] = [States],
    [PolicyLossLimitAggregateCap] = [PolicyLossLimitAggregateCap],
    [PolicyLossLimitCapClarification] = [PolicyLossLimitCapClarification],
    [PolicyLossLimitOccurrenceCap] = [PolicyLossLimitOccurrenceCap],
    [PolicyLossLimitPDOccurrenceCap] = [PolicyLossLimitPDOccurrenceCap],
    [RAvLOD] = [RAvLOD],
    [TotalSubjectPremium] = SUM([TotalSubjectPremium]),
    [TargetParticipation] = AVG([TargetParticipation]),
    [TargetParticipationPercentage] = AVG([TargetParticipation]) / SUM([TotalSubjectPremium]),
    [AssumedPolicyLengthMonths] = [AssumedPolicyLengthMonths],
    --[ULAEGWPorGEP], [ULAEFlag], -- Do we need this?
    [ULAEOutsideCedingCommission] = MAX([ULAEOutsideCedingCommission]),
    [ULAETreatmentInsidevOutside] = [ULAETreatmentInsidevOutside],
    [ULAETreatementAtActual] = [ULAETreatementAtActual],
    [ULAETreatmentPartOfLoss] = [ULAETreatmentPartOfLoss],
    [ALAE] = [ALAE],
    [ALAETreatmentCapped] = [ALAETreatmentCapped],
    [ALAETreatmentAtActual] = [ALAETreatmentAtActual],
    [Admitted] = [Admitted],
    [ES] = [ES],
    [InheritedUEPROutsideParticipation] = [InheritedUEPROutsideParticipation],
    [KeyLimits] = [KeyLimits],
    [ULAEorALAE] = [ULAEorALAE],
    [ReinsuranceBrokerCommission] = [ReinsuranceBrokerCommission],
    [SeparateExpenses] = MAX([SeparateExpenses]),
    [CollateralTerms] = [CollateralTerms],
    [ScheduleFMultiple] = [ScheduleFMultiple],
    [UEPRMultiple] = [UEPRMultiple],
    [CollateralTerms_1] = [CollateralTerms_1],
    [PostingFrequency] = [PostingFrequency],
    [CommissionNotes] = [CommissionNotes],
    [FlatCommission] = [FlatCommission],
    [MinimumCedingCommission] = [MinimumCedingCommission],
    [MinimumCommission] = [MinimumCommission],
    [ProvisionalCedingCommission] = [ProvisionalCedingCommission],
    [ProvisionalCommission] = [ProvisionalCommission],
    [MaximumCedingCommission] = [MaximumCedingCommission],
    [MaximumCommission] = [MaximumCommission],
    [MinimumCedingCommissionLLAERatio] = [MinimumCedingCommissionLLAERatio],
    [MinimumLossRatio] = [MinimumLossRatio],
    [ProvisionalCedingCommissionLLAERatio] = [ProvisionalCedingCommissionLLAERatio],
    [ProvisionalLossRatio] = [ProvisionalLossRatio],
    [MaximumCedingCommissionLLAERatio] = [MaximumCedingCommissionLLAERatio],
    [MaximumLossRatio] = [MaximumLossRatio],
    [LossRatioCap] = [LossRatioCap],
    [OccurenceCap] = [OccurenceCap],
    [CorridorStart] = [CorridorStart],
    [LLAECorridorAttachmentLR] = [LLAECorridorAttachmentLR],
    [CorridorEnd] = [CorridorEnd],
    [LLAECorridorEndLR] = [LLAECorridorEndLR],
    [LLAECorridorRetained] = [LLAECorridorRetained],
    [EstimatedPayoutDuration] = [EstimatedPayoutDuration],
    [Suffix] = [Suffix],
    [Contact] = [Contact],
    [Differentiator] = [Differentiator],
    [Narrative] = [Narrative],
    [Actuary] = [Actuary],
    [ActuarialComment] = [ActuarialComment],
    [ActuarialAuthor] = [ActuarialAuthor],
    [PriorNoImprovementCombinedRatio] = [PriorNoImprovementCombinedRatio],
    [PriorHalfImprovementCombinedRatio] = [PriorHalfImprovementCombinedRatio],
    [IndustryCombinedRatio] = [IndustryCombinedRatio],
    [PriorBreakevenLALAERatio] = [PriorBreakevenLALAERatio],
    [MiscellaneousNotes] = [MiscellaneousNotes],
    [PriorNoImprovementGrossLALAERatio] = [PriorNoImprovementGrossLALAERatio],
    [PriorHalfImprovementGrossLALAERatio] = [PriorHalfImprovementGrossLALAERatio],
    [ActuarialAnalysisNote] = MAX([ActuarialAnalysisNote]),
    [ActuarialViewpoint] = MAX([ActuarialViewpoint]),
    [PriorNoImprovmentNetLALAERatio] = [PriorNoImprovmentNetLALAERatio],
    [PriorHalfImprovmentNetLALAERatio] = [PriorHalfImprovmentNetLALAERatio]
FROM [CleanUpData]
/*
WHERE [StartDate] <= SYSDATETIME() --'2024-09-30'
    -- AND lob.[ID] IS NULL -- Issues needing Northern Re to fix
    -- AND p.[Name] = 'ATM'
    AND jr.[Name] IS NULL
*/
GROUP BY 
    [ConcatenatedKey],
    [StatusID],
    [Status],
    [EffectiveDate],
    [ExpirationDate],
    [Panel],
    [Carrier],
    [PrimaryLOB],
    [SecondaryLOB],
    [States],
    [PolicyLossLimitAggregateCap],
    [PolicyLossLimitCapClarification],
    [PolicyLossLimitOccurrenceCap],
    [PolicyLossLimitPDOccurrenceCap],
    [RAvLOD],
    [AssumedPolicyLengthMonths],
    [ULAETreatmentInsidevOutside],
    [ULAETreatementAtActual],
    [ULAETreatmentPartOfLoss],
    [ALAE],
    [ALAETreatmentCapped],
    [ALAETreatmentAtActual],
    [Admitted],
    [ES],
    [InheritedUEPROutsideParticipation],
    [KeyLimits],
    [ULAEorALAE],
    [ReinsuranceBrokerCommission],
    [CollateralTerms],
    [ScheduleFMultiple],
    [UEPRMultiple],
    [CollateralTerms_1],
    [PostingFrequency],
    [CommissionNotes],
    [FlatCommission],
    [MinimumCedingCommission],
    [MinimumCommission],
    [ProvisionalCedingCommission],
    [ProvisionalCommission],
    [MaximumCedingCommission],
    [MaximumCommission],
    [MinimumCedingCommissionLLAERatio],
    [MinimumLossRatio],
    [ProvisionalCedingCommissionLLAERatio],
    [ProvisionalLossRatio],
    [MaximumCedingCommissionLLAERatio],
    [MaximumLossRatio],
    [LossRatioCap],
    [OccurenceCap],
    [CorridorStart],
    [LLAECorridorAttachmentLR],
    [CorridorEnd],
    [LLAECorridorEndLR],
    [LLAECorridorRetained],
    [EstimatedPayoutDuration],
    [Suffix],
    [Contact],
    [Differentiator],
    [Narrative],
    [Actuary],
    [ActuarialComment],
    [ActuarialAuthor],
    [PriorNoImprovementCombinedRatio],
    [PriorHalfImprovementCombinedRatio],
    [IndustryCombinedRatio],
    [PriorBreakevenLALAERatio],
    [MiscellaneousNotes],
    [PriorNoImprovementGrossLALAERatio],
    [PriorHalfImprovementGrossLALAERatio],
    [PriorNoImprovmentNetLALAERatio],
    [PriorHalfImprovmentNetLALAERatio]
ORDER BY 1
;
