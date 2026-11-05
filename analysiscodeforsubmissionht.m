% directory structure expected: Data / Experiment2 / 1(/2/3/etc)
% (each participant folder should contain a baseline no-adapt file and an adapted file)

close all
clear all
clc

%% Set experiment

experiment = 1;

%% Read participant-specific landmark coordinates

faceCoords = readtable(fullfile(pwd,'Data','FaceCoordinatesExp1.xlsx'));

% Face landmarks tested (must match saveData.Positions for all subjects)
landmarks = {'Left Ear','Left Middle','Left Lateral','Left Pupil',...
    'Left Medial','Centre','Right Medial','Right Pupil',...
    'Right Lateral','Right Middle','Right Ear'};

numLandmarks = length(landmarks);


%% Read in data

common_path = [pwd,filesep,'Data',filesep,'Experiment',num2str(experiment),filesep];

dCommon = dir(common_path);
dCommon = dCommon(~strncmpi('.', {dCommon.name}, 1));

% Sort participant folders numerically
folder_list_numeric = str2double({dCommon.name});
[~,idxName] = sort(folder_list_numeric);
dCommon = dCommon(idxName);

numParts = size(dCommon,1);


%% Preallocate

propEyeContactAll = nan(numLandmarks,2,numParts);

centroidAll = nan(2,numParts);

condition_map = nan(1,numParts);
subject_map = cell(1,numParts);

% Store morphology-adjusted landmark locations
landmark_x_all = nan(numLandmarks,numParts);


%% Read participant data

for p = 1:numParts


    % Check participant has landmark data
    if p > height(faceCoords)
        error('Not enough rows in FaceCoordinatesExp1.xlsx for participants')
    end


    % Participant-specific physical landmark coordinates
    
    landmark_x = table2array(faceCoords(p,2:end));

  
    % INPUT IF, Normalize so right ear = +1
    

    % Save participant-specific coordinates
    landmark_x_all(:,p) = landmark_x;


    % Find participant folder

    folder = [common_path,dCommon(p).name,filesep];

    dFolder = dir([folder,'*.mat']);

    numRuns = size(dFolder,1);

    if numRuns ~= 2
        error(['Unexpected number of datafiles in folder: ', dCommon(p).name])
    end



    for run = 1:numRuns


        % Load data
        load([folder,dFolder(run).name]);

% Force participant 32's adaptation condition to 2
if strcmp(saveData.subject_id,'32') && saveData.adapt_cond > 0
    saveData.adapt_cond = 2;
end

% Force participant 33's adaptation condition to 2
if strcmp(saveData.subject_id,'33') && saveData.adapt_cond > 0
    saveData.adapt_cond = 2;
end


% Force participant 15's adaptation condition to 2 (recall i made that
% error)

if strcmp(saveData.subject_id,'15') && saveData.adapt_cond > 0
    saveData.adapt_cond = 2;
end


        data = saveData.ResultsTable;


        % Remove trials without response
        data = data(~isnan(data.Response),:);


        % Reset response vector
        propEyeContact = zeros(numLandmarks,1);



        % Calculate proportion eye contact responses

        for i = 1:numLandmarks

            idxCond = strcmp(data.Word,landmarks{i});

            if sum(idxCond)==0
                error(['No trials found for ', landmarks{i}])
            end

            propEyeContact(i) = sum(data.Response(idxCond)) / sum(idxCond);

        end



       propEyeContact = propEyeContact(:);
landmark_x = landmark_x(:);

centroid = sum(propEyeContact .* landmark_x) / sum(propEyeContact);



        % Store baseline/adaptation

        if saveData.adapt_cond == 0

            propEyeContactAll(:,1,p) = propEyeContact;
            centroidAll(1,p) = centroid;


        elseif saveData.adapt_cond > 0

            propEyeContactAll(:,2,p) = propEyeContact;
            centroidAll(2,p) = centroid;

            condition_map(p) = saveData.adapt_cond;
            subject_map{p} = saveData.subject_id;

        end



        clear saveData data propEyeContact centroid

    end

end



%% Individual Subject Plots


for p = 1:numParts


    figure


    if condition_map(p)==1

        title_text=[subject_map{p},' | Adapt Left'];
        filename=['AdaptLeft_',subject_map{p}];

    elseif condition_map(p)==2

        title_text=[subject_map{p},' | Adapt Right'];
        filename=['AdaptRight_',subject_map{p}];

    else

        title_text=['Participant ',num2str(p)];

    end



    % Participant-specific x-axis

    x_values = landmark_x_all(:,p);


    y_values_baseline = propEyeContactAll(:,1,p);

    y_values_adapted = propEyeContactAll(:,2,p);



    ylim([0 1]);

    xlim([min(x_values)-5, max(x_values)+5]);

    hold on


    % Baseline

    plot(x_values,...
        y_values_baseline,...
        'b^-',...
        'linewidth',2);


    plot([centroidAll(1,p) centroidAll(1,p)],...
        [0 1],...
        'b:',...
        'linewidth',2);



    % Adapted

    plot(x_values,...
        y_values_adapted,...
        'r^-',...
        'linewidth',2);


    plot([centroidAll(2,p) centroidAll(2,p)],...
        [0 1],...
        'r:',...
        'linewidth',2);


    hold off



    axis square


    ax=gca;

    ax.XAxisLocation='origin';



    xticks(x_values);

   labels = strcat(landmarks', newline, compose('%.0f', x_values));
xticklabels(labels)



xlabel('Anatomical landmark',...
    'FontSize',12,...
    'FontName','sans serif',...
    'FontWeight','bold');
ylabel('Proportion of "Yes" Eye Contact Responses',...
    'FontSize',12,...
    'FontName','sans serif',...
    'FontWeight','bold');

    set(gca,'fontsize',10);


    legend({'Baseline','','Adapted',''},...
        'location','northeastoutside');


    title(title_text);



end


%% ==========================================================
%Let's look at the breakdown of 
idxLeft = condition_map == 1;

baselineLeft = centroidAll(1,idxLeft);
adaptedLeft  = centroidAll(2,idxLeft);

[hL,pL,ciL,statsL] = ttest(adaptedLeft, baselineLeft);

shiftLeft = adaptedLeft - baselineLeft;

fprintf('Adapt Left\n');
fprintf('Mean shift = %.3f\n',mean(shiftLeft));
fprintf('SD = %.3f\n',std(shiftLeft));
fprintf('t(%d) = %.3f\n',statsL.df,statsL.tstat);
fprintf('p = %.4f\n\n',pL);


idxLeft = condition_map == 1;

baselineLeft = centroidAll(1,idxLeft);
adaptedLeft  = centroidAll(2,idxLeft);

[hL,pL,ciL,statsL] = ttest(adaptedLeft, baselineLeft);

shiftLeft = adaptedLeft - baselineLeft;

cohensD_Left = mean(shiftLeft) / std(shiftLeft);

fprintf('Adapt Left\n');
fprintf('Mean shift = %.3f\n',mean(shiftLeft));
fprintf('SD = %.3f\n',std(shiftLeft));
fprintf('t(%d) = %.3f\n',statsL.df,statsL.tstat);
fprintf('p = %.4f\n',pL);
fprintf("Cohen's d = %.3f\n\n",cohensD_Left);




%% ==========================================================
% Centroid shift analysis + Cohen's dz
% ==========================================================

baselineCentroid = centroidAll(1,:);
adaptedCentroid  = centroidAll(2,:);

% Align direction:
% condition 1 = Adapt Left
% condition 2 = Adapt Right

baselineRecoded = baselineCentroid;
adaptedRecoded  = adaptedCentroid;

baselineRecoded(condition_map == 1) = -baselineRecoded(condition_map == 1);
adaptedRecoded(condition_map == 1)  = -adaptedRecoded(condition_map == 1);


% Difference scores
centroidShift = adaptedRecoded - baselineRecoded;

%% ==========================================================
% Overall Mean Centroid Shift + 95% CI
% Left and Right Adaptation Combined
% Left adaptation directionally recoded
% ==========================================================

% Calculate individual centroid shifts
centroidShift = adaptedRecoded - baselineRecoded;

% Remove missing observations
validShift = centroidShift(isfinite(centroidShift));
n = length(validShift);

% Descriptive statistics
meanShift = mean(validShift);
sdShift = std(validShift);
seShift = sdShift / sqrt(n);

% Paired-samples t-test against zero
[~,p,ci,stats] = ttest(validShift,0);

% Output
fprintf('\n----------------------------------------\n');
fprintf('Overall Centroid Shift Analysis\n');
fprintf('----------------------------------------\n');

fprintf('N = %d\n',n);
fprintf('Mean shift = %.3f\n',meanShift);
fprintf('SD shift = %.3f\n',sdShift);
fprintf('SE = %.3f\n',seShift);

fprintf('95%% CI for mean shift = [%.3f, %.3f]\n', ...
    ci(1),ci(2));

fprintf('\nPaired-samples t-test:\n');
fprintf('t(%d) = %.3f\n',stats.df,stats.tstat);
fprintf('p = %.4f\n',p);

% Paired t-test
[h,p,ci,stats] = ttest(adaptedRecoded, baselineRecoded);

% Cohen's dz But is this the pooled standard deviation? hmnn...
meanShift = mean(centroidShift);
sdShift = std(centroidShift);

cohen_dz = meanShift / sdShift;


% Output

fprintf('\n----------------------------------------\n');
fprintf('Centroid Shift Analysis\n');
fprintf('----------------------------------------\n');

fprintf('Mean centroid shift = %.3f\n', meanShift);
fprintf('SD centroid shift   = %.3f\n', sdShift);

fprintf('Cohen''s dz = %.3f\n\n', cohen_dz);

fprintf('Paired t-test:\n');
fprintf('t(%d) = %.3f\n', stats.df, stats.tstat);
fprintf('p = %.10f\n', p);
fprintf('95%% CI = [%.3f, %.3f]\n', ci(1), ci(2));


table(subject_map', condition_map', ...
    centroidAll(1,:)', ...
    centroidAll(2,:)', ...
    centroidShift')


%% ==========================================================
%  2 × 2 Mixed ANOVA
%  Within-subject factor: Time (Baseline vs Adapted)
%  Between-subject factor: Adaptation Direction (Left vs Right)
% ==========================================================

% Create analysis table
T = table( ...
    baselineRecoded', ...
    adaptedRecoded', ...
    categorical(condition_map)', ...
    'VariableNames', ...
    {'Baseline','Adapted','Direction'});

% Define within-subject factor
Within = table( ...
    categorical({'Baseline';'Adapted'}), ...
    'VariableNames',{'Aftereffect'});

% Fit repeated-measures model
rm = fitrm(T,'Baseline-Adapted ~ Direction', ...
    'WithinDesign',Within);

% Mixed ANOVA
ranovatbl = ranova(rm,'WithinModel','Aftereffect');

%% ==========================================================
% Within-Subject Main Effect: Aftereffect
% Baseline vs Adapted
% ==========================================================

% Find the Aftereffect row
idxAftereffect = strcmp( ...
    ranovatbl.Properties.RowNames, ...
    '(Intercept):Aftereffect');

% Find the corresponding error row
idxErrorAftereffect = strcmp( ...
    ranovatbl.Properties.RowNames, ...
    'Error(Aftereffect)');

% Extract statistics
F_aftereffect   = ranovatbl.F(idxAftereffect);
df_aftereffect = ranovatbl.DF(idxAftereffect);
p_aftereffect  = ranovatbl.pValue(idxAftereffect);

df_error_aftereffect = ranovatbl.DF(idxErrorAftereffect);

% Partial eta squared
eta_p2_aftereffect = ...
    (F_aftereffect .* df_aftereffect) ./ ...
    ((F_aftereffect .* df_aftereffect) + df_error_aftereffect);

% Print results
fprintf('\n==============================================\n');
fprintf('WITHIN-SUBJECT MAIN EFFECT: AFTEREFFECT\n');
fprintf('==============================================\n');

fprintf('F(%d,%d) = %.3f\n', ...
    df_aftereffect, ...
    df_error_aftereffect, ...
    F_aftereffect);

fprintf('p = %.3e\n', p_aftereffect);

fprintf('Partial eta squared = %.3f\n', ...
    eta_p2_aftereffect);

fprintf('==============================================\n\n');


disp(' ');
disp('==============================');
disp('Repeated-Measures ANOVA');
disp('==============================');
disp(ranovatbl);

% Between-subject effect
betweenTbl = anova(rm);

%% ==========================================================
% Between-Subject ANOVA: Adaptation Direction
% ==========================================================

% The between-subject ANOVA table has:
% Row 1 = Intercept
% Row 2 = Direction
% Row 3 = Error

% Extract Direction effect
F_direction   = betweenTbl.F(2);
df_direction = betweenTbl.DF(2);
p_direction   = betweenTbl.pValue(2);

% Extract error term
df_error_direction = betweenTbl.DF(3);

% Partial eta squared
eta_p2_direction = ...
    (F_direction .* df_direction) ./ ...
    ((F_direction .* df_direction) + df_error_direction);

% Print between-subject ANOVA
fprintf('\n==============================================\n');
fprintf('BETWEEN-SUBJECT ANOVA: ADAPTATION DIRECTION\n');
fprintf('==============================================\n');

fprintf('F(%d,%d) = %.3f\n', ...
    df_direction, ...
    df_error_direction, ...
    F_direction);

fprintf('p = %.4f\n', p_direction);

fprintf('Partial eta squared = %.3f\n', ...
    eta_p2_direction);

fprintf('==============================================\n\n');
%% ==========================================================
% Partial Eta Squared for 2 × 2 Mixed ANOVA
% ==========================================================

%% ----------------------------------------------------------
% 1. Within-subject effect: Aftereffect
%    Baseline vs Adapted
% ----------------------------------------------------------

% Row: (Intercept):Aftereffect
idxAftereffect = strcmp( ...
    ranovatbl.Properties.RowNames, ...
    '(Intercept):Aftereffect');

% Error term for Aftereffect
idxErrorAftereffect = strcmp( ...
    ranovatbl.Properties.RowNames, ...
    'Error(Aftereffect)');

F_within  = ranovatbl.F(idxAftereffect);
df_within = ranovatbl.DF(idxAftereffect);
df_error  = ranovatbl.DF(idxErrorAftereffect);

eta_p2_within = ...
    (F_within .* df_within) ./ ...
    ((F_within .* df_within) + df_error);


%% ----------------------------------------------------------
% 2. Between-subject effect: Direction
%    Adapt Left vs Adapt Right
% ----------------------------------------------------------

% Direction row is directly available in ranovatbl
idxDirection = strcmp( ...
    ranovatbl.Properties.RowNames, ...
    'Direction');

idxErrorDirection = strcmp( ...
    ranovatbl.Properties.RowNames, ...
    'Error');

F_between  = ranovatbl.F(idxDirection);
df_between = ranovatbl.DF(idxDirection);
df_error_between = ranovatbl.DF(idxErrorDirection);

eta_p2_between = ...
    (F_between .* df_between) ./ ...
    ((F_between .* df_between) + df_error_between);


%% ----------------------------------------------------------
% 3. Interaction: Aftereffect × Direction
% ----------------------------------------------------------

idxInteraction = strcmp( ...
    ranovatbl.Properties.RowNames, ...
    'Direction:Aftereffect');

F_interaction  = ranovatbl.F(idxInteraction);
df_interaction = ranovatbl.DF(idxInteraction);

eta_p2_interaction = ...
    (F_interaction .* df_interaction) ./ ...
    ((F_interaction .* df_interaction) + df_error);


%% ----------------------------------------------------------
% Print results
% ----------------------------------------------------------

fprintf('\n==============================================\n');
fprintf('PARTIAL ETA SQUARED — 2 × 2 MIXED ANOVA\n');
fprintf('==============================================\n');

fprintf('Within-subject effect (Aftereffect):   eta_p^2 = %.3f\n', ...
    eta_p2_within);

fprintf('Between-subject effect (Direction):    eta_p^2 = %.3f\n', ...
    eta_p2_between);

fprintf('Interaction (Aftereffect × Direction): eta_p^2 = %.3f\n', ...
    eta_p2_interaction);

fprintf('==============================================\n\n');


idxRight = condition_map==2;

[h,p,ci,stats] = ttest(adaptedRecoded(idxRight),baselineRecoded(idxRight));

fprintf('\nSimple Effect: Adapt Right\n');
fprintf('t(%d)=%.3f, p=%.4f\n',stats.df,stats.tstat,p);


[h,p,ci,stats] = ttest2( ...
    baselineRecoded(idxLeft), ...
    baselineRecoded(idxRight));

fprintf('\nBaseline Comparison\n');
fprintf('t(%d)=%.3f, p=%.4f\n',stats.df,stats.tstat,p);


[h,p,ci,stats] = ttest2( ...
    adaptedRecoded(idxLeft), ...
    adaptedRecoded(idxRight));

fprintf('\nAdapted Comparison\n');
fprintf('t(%d)=%.3f, p=%.4f\n',stats.df,stats.tstat,p);

alpha = 0.05;
alphaCorrected = alpha/4;

fprintf('\nBonferroni-corrected alpha = %.4f\n',alphaCorrected);


%% ==========================================================
% Planned comparisons following mixed ANOVA
% Bonferroni correction (3 tests)
% ==========================================================

idxLeft  = condition_map == 1;
idxRight = condition_map == 2;

%% 1. Simple effect: Left adaptation

[~,p1,ci1,stats1] = ttest( ...
    adaptedRecoded(idxLeft), ...
    baselineRecoded(idxLeft));

%% 2. Simple effect: Right adaptation

[~,p2,ci2,stats2] = ttest( ...
    adaptedRecoded(idxRight), ...
    baselineRecoded(idxRight));

%% 3. Compare aftereffect magnitude between groups

shiftLeft  = centroidShift(idxLeft);
shiftRight = centroidShift(idxRight);

[~,p3,ci3,stats3] = ttest2( ...
    shiftLeft, ...
    shiftRight);

%% Bonferroni correction

alpha = 0.05;
alphaCorrected = alpha/3;

pvals = [p1 p2 p3];
pBonf = min(pvals*3,1);

disp(' ');
disp('========================================');
disp('Planned Comparisons (Bonferroni Corrected)');
disp('========================================');

disp(table( ...
    {'Left: Baseline vs Adapted'; ...
     'Right: Baseline vs Adapted'; ...
     'Aftereffect: Left vs Right'}, ...
    pvals', ...
    pBonf', ...
    'VariableNames',{'Comparison','Raw_p','Bonferroni_p'}));

fprintf('\nBonferroni-corrected alpha = %.4f\n',alphaCorrected);

fprintf('\nLeft adaptation:\n');
fprintf('t(%d) = %.3f, raw p = %.4f, corrected p = %.4f\n', ...
    stats1.df, stats1.tstat, p1, pBonf(1));

fprintf('\nRight adaptation:\n');
fprintf('t(%d) = %.3f, raw p = %.4f, corrected p = %.4f\n', ...
    stats2.df, stats2.tstat, p2, pBonf(2));

fprintf('\nAftereffect magnitude (Left vs Right):\n');
fprintf('t(%d) = %.3f, raw p = %.4f, corrected p = %.4f\n', ...
    stats3.df, stats3.tstat, p3, pBonf(3));


%% Mean baseline distribution

% Mean physical landmark positions
mean_x = mean(landmark_x_all,2);

% Mean baseline eye-contact responses
meanBaseline = mean(propEyeContactAll(:,1,:),3);

% Mean baseline centroid
meanBaselineCentroid = mean(centroidAll(1,:));

figure
hold on

plot(mean_x,meanBaseline,'b^-','LineWidth',2)

plot([meanBaselineCentroid meanBaselineCentroid],...
     [0 1],...
     'b:',...
     'LineWidth',2)

ylim([0 1])
xlim([min(mean_x)-5 max(mean_x)+5])

axis square
ax = gca;
ax.XAxisLocation = 'origin';

xticks(mean_x)

labels = strcat(landmarks',' (',compose('%.0f',mean_x),')');
xticklabels(labels)


xlabel('Anatomical landmark',...
    'FontSize',12,...
    'FontName','sans serif',...
    'FontWeight','bold');
ylabel('Proportion of "Yes" Eye Contact Responses',...
    'FontSize',12,...
    'FontName','sans serif',...
    'FontWeight','bold');
title('')

set(gca,'FontSize',10.5,'FontName','sans serif');




%% ==========================================================
% Mean plot - Left Adaptation
% ==========================================================

idx = condition_map == 1;

mean_x = mean(landmark_x_all(:,idx),2);

baseline = squeeze(propEyeContactAll(:,1,idx));
adapted  = squeeze(propEyeContactAll(:,2,idx));

meanBaseline = mean(baseline,2);
meanAdapted  = mean(adapted,2);

meanBaselineCentroid = mean(centroidAll(1,idx));
meanAdaptedCentroid  = mean(centroidAll(2,idx));

figure
hold on

plot(mean_x,meanBaseline,'b^-','LineWidth',2)
plot([meanBaselineCentroid meanBaselineCentroid],[0 1],'b:','LineWidth',2)

plot(mean_x,meanAdapted,'r^-','LineWidth',2)
plot([meanAdaptedCentroid meanAdaptedCentroid],[0 1],'r:','LineWidth',2)

ylim([0 1])
xlim([min(mean_x)-5 max(mean_x)+5])

axis square
ax=gca;
ax.XAxisLocation='origin';

xticks(mean_x)
labels = strcat(landmarks',' (',compose('%.0f',mean_x),')');
xticklabels(labels)

xlabel('Anatomical landmark',...
    'FontSize',12,...
    'FontName','sans serif',...
    'FontWeight','bold');
ylabel('Proportion of "Yes" Eye Contact Responses',...
    'FontSize',12,...
    'FontName','sans serif',...
    'FontWeight','bold');
title('')

legend({'Baseline','','Adapted',''},...
    'Location','northeastoutside')

set(gca,'FontSize',10.5,'FontName','sans serif');

box off
hold off

%% ==========================================================
% Mean plot - Right Adaptation
% ==========================================================

idx = condition_map == 2;

mean_x = mean(landmark_x_all(:,idx),2);

baseline = squeeze(propEyeContactAll(:,1,idx));
adapted  = squeeze(propEyeContactAll(:,2,idx));

meanBaseline = mean(baseline,2);
meanAdapted  = mean(adapted,2);

meanBaselineCentroid = mean(centroidAll(1,idx));
meanAdaptedCentroid  = mean(centroidAll(2,idx));

figure
hold on

plot(mean_x,meanBaseline,'b^-','LineWidth',2)
plot([meanBaselineCentroid meanBaselineCentroid],[0 1],'b:','LineWidth',2)

plot(mean_x,meanAdapted,'r^-','LineWidth',2)
plot([meanAdaptedCentroid meanAdaptedCentroid],[0 1],'r:','LineWidth',2)

ylim([0 1])
xlim([min(mean_x)-5 max(mean_x)+5])

axis square
ax=gca;
ax.XAxisLocation='origin';

xticks(mean_x)
labels = strcat(landmarks',' (',compose('%.0f',mean_x),')');
xticklabels(labels)

xlabel('Anatomical landmark',...
    'FontSize',12,...
    'FontName','sans serif',...
    'FontWeight','bold');
ylabel('Proportion of "Yes" Eye Contact Responses',...
    'FontSize',12,...
    'FontName','sans serif',...
    'FontWeight','bold');

title('')

legend({'Baseline','','Adapted',''},...
    'Location','northeastoutside')

set(gca,'FontSize',12,'FontName','sans serif');

box off
hold off


baselineLeftEye  = squeeze(propEyeContactAll(4,1,:));
baselineRightEye = squeeze(propEyeContactAll(8,1,:));

eyeDifference = baselineLeftEye - baselineRightEye;

idxLeft  = condition_map == 1;
idxRight = condition_map == 2;

diffLeftGroup  = eyeDifference(idxLeft);
diffRightGroup = eyeDifference(idxRight);

[h,p,ci,stats] = ttest2(diffLeftGroup,diffRightGroup);

fprintf('\nBaseline Left-vs-Right Eye Bias\n');
fprintf('t(%d)=%.3f\n',stats.df,stats.tstat);
fprintf('p=%.4f\n',p);

n1 = numel(diffLeftGroup);
n2 = numel(diffRightGroup);

pooledSD = sqrt(((n1-1)*var(diffLeftGroup) + (n2-1)*var(diffRightGroup)) / (n1+n2-2));

cohen_d = (mean(diffLeftGroup)-mean(diffRightGroup)) / pooledSD;

fprintf("Cohen's d = %.3f\n",cohen_d);



%% ==========================================================
% Centroid Descriptive Statistics
% ==========================================================

idxLeft  = condition_map == 1;
idxRight = condition_map == 2;

%% All participants

meanBaseline_All = mean(centroidAll(1,:));
sdBaseline_All   = std(centroidAll(1,:));

meanAdapted_All = mean(centroidAll(2,:));
sdAdapted_All   = std(centroidAll(2,:));

%% Left adaptation participants

meanBaseline_Left = mean(centroidAll(1,idxLeft));
sdBaseline_Left   = std(centroidAll(1,idxLeft));

meanAdapted_Left = mean(centroidAll(2,idxLeft));
sdAdapted_Left   = std(centroidAll(2,idxLeft));

%% Right adaptation participants

meanBaseline_Right = mean(centroidAll(1,idxRight));
sdBaseline_Right   = std(centroidAll(1,idxRight));

meanAdapted_Right = mean(centroidAll(2,idxRight));
sdAdapted_Right   = std(centroidAll(2,idxRight));

%% Display

fprintf('\n==============================\n');
fprintf('Centroid Descriptive Statistics\n');
fprintf('==============================\n');

fprintf('\nAll Participants\n');
fprintf('Baseline: Mean = %.2f, SD = %.2f\n', ...
    meanBaseline_All, sdBaseline_All);
fprintf('Adapted : Mean = %.2f, SD = %.2f\n', ...
    meanAdapted_All, sdAdapted_All);

fprintf('\nLeft Adaptation\n');
fprintf('Baseline: Mean = %.2f, SD = %.2f\n', ...
    meanBaseline_Left, sdBaseline_Left);
fprintf('Adapted : Mean = %.2f, SD = %.2f\n', ...
    meanAdapted_Left, sdAdapted_Left);

fprintf('\nRight Adaptation\n');
fprintf('Baseline: Mean = %.2f, SD = %.2f\n', ...
    meanBaseline_Right, sdBaseline_Right);
fprintf('Adapted : Mean = %.2f, SD = %.2f\n', ...
    meanAdapted_Right, sdAdapted_Right);


%new things!

%% ==========================================================
% Overall Mean Baseline vs Adapted Distribution
% All participants combined
% Left/right adaptation directionally aligned
% ==========================================================

% Store aligned data
alignedX        = nan(numLandmarks,numParts);
alignedBaseline = nan(numLandmarks,numParts);
alignedAdapted  = nan(numLandmarks,numParts);

for p = 1:numParts

    x = landmark_x_all(:,p);
    baseline = propEyeContactAll(:,1,p);
    adapted  = propEyeContactAll(:,2,p);

    if condition_map(p) == 1
        % LEFT adaptation:
        % flip physical direction AND reverse landmark order

        alignedX(:,p)        = -flipud(x);
        alignedBaseline(:,p) = flipud(baseline);
        alignedAdapted(:,p)  = flipud(adapted);

    elseif condition_map(p) == 2
        % RIGHT adaptation:
        % leave as is

        alignedX(:,p)        = x;
        alignedBaseline(:,p) = baseline;
        alignedAdapted(:,p)  = adapted;
    end

end


%% ==========================================================
% Mean physical morphology
% ==========================================================

meanX = mean(alignedX,2);


%% ==========================================================
% Mean baseline and adapted responses
% ==========================================================

meanBaseline = mean(alignedBaseline,2);
meanAdapted  = mean(alignedAdapted,2);


%% ==========================================================
% Directionally aligned centroids
% ==========================================================

baselineAligned = centroidAll(1,:);
adaptedAligned  = centroidAll(2,:);

% Flip LEFT adaptation centroids
baselineAligned(condition_map == 1) = ...
    -baselineAligned(condition_map == 1);

adaptedAligned(condition_map == 1) = ...
    -adaptedAligned(condition_map == 1);


%% Mean centroid across ALL participants

meanBaselineCentroid = mean(baselineAligned);
meanAdaptedCentroid  = mean(adaptedAligned);


%% ==========================================================
% Plot
% ==========================================================

figure
hold on

% Baseline distribution
plot(meanX,...
     meanBaseline,...
     'b^-',...
     'LineWidth',2,...
     'MarkerSize',7);

% Baseline centroid
plot([meanBaselineCentroid meanBaselineCentroid],...
     [0 1],...
     'b:',...
     'LineWidth',2); 

% Adapted distribution
plot(meanX,...
     meanAdapted,...
     'r^-',...
     'LineWidth',2,...
     'MarkerSize',7);

% Adapted centroid
plot([meanAdaptedCentroid meanAdaptedCentroid],...
     [0 1],...
     'r:',...
     'LineWidth',2);


%% ==========================================================
% Formatting
% ==========================================================

ylim([0 1]);

xlim([min(meanX)-5 max(meanX)+5]);

axis square

ax = gca;
ax.XAxisLocation = 'origin';

% IMPORTANT:
% meanX is already in physical left-to-right order,
% so no sorting is required.

xticks(meanX);

labels = strcat(landmarks',...
    ' (',...
    compose('%.0f',meanX),...
    ')');

xticklabels(labels);

xlabel('Anatomical landmark',...
    'FontSize',12,...
    'FontName','sans serif',...
    'FontWeight','bold');
ylabel('Proportion of "Yes" Eye Contact Responses',...
    'FontSize',12,...
    'FontName','sans serif',...
    'FontWeight','bold');

title('');

legend({'Baseline','','Adapted',''},...
       'Location','northeastoutside');

set(gca,'FontSize',12,'FontName','sans serif');

box off
hold off



%assumption checks!



%% ==========================================================
% Assumption Checks
% ==========================================================

%% ==========================================================
% Assumption Checks
% ==========================================================

% Separate participants by adaptation direction
idxLeft  = condition_map == 1;
idxRight = condition_map == 2;

% Centroids for each group
baselineLeft  = centroidAll(1,idxLeft);
adaptedLeft   = centroidAll(2,idxLeft);

baselineRight = centroidAll(1,idxRight);
adaptedRight  = centroidAll(2,idxRight);


%% ==========================================================
% Shapiro-Wilk normality tests
% ==========================================================

fprintf('\n========================================\n');
fprintf('Shapiro-Wilk Normality Tests\n');
fprintf('========================================\n');

Results_BL = normalitytest(baselineLeft);
Results_AL = normalitytest(adaptedLeft);
Results_BR = normalitytest(baselineRight);
Results_AR = normalitytest(adaptedRight);

p_BL = Results_BL(7,2);
p_AL = Results_AL(7,2);
p_BR = Results_BR(7,2);
p_AR = Results_AR(7,2);

fprintf('Baseline - Left:   p = %.4f\n', p_BL);
fprintf('Adapted - Left:    p = %.4f\n', p_AL);
fprintf('Baseline - Right:  p = %.4f\n', p_BR);
fprintf('Adapted - Right:   p = %.4f\n', p_AR);


%% ==========================================================
% Shapiro-Wilk Test: Paired Differences
% ==========================================================

Results_diff = normalitytest(centroidShift);

% Extract Shapiro-Wilk statistic and p-value
W_diff = Results_diff(7,1);
p_diff = Results_diff(7,2);

fprintf('\n========================================\n');
fprintf('Shapiro-Wilk Test: Paired Differences\n');
fprintf('========================================\n');

fprintf('Centroid difference: W = %.4f, p = %.4f\n', ...
    W_diff, p_diff);


%% ==========================================================
% Levene's tests
% ==========================================================

fprintf('\n========================================\n');
fprintf('Levene''s Tests\n');
fprintf('========================================\n');

% Baseline: Left vs Right
[pLevBaseline,~] = vartestn( ...
    [baselineLeft, baselineRight]', ...
    [ones(length(baselineLeft),1);
     2*ones(length(baselineRight),1)], ...
    'TestType','LeveneAbsolute', ...
    'Display','off');

% Adapted: Left vs Right
[pLevAdapted,~] = vartestn( ...
    [adaptedLeft, adaptedRight]', ...
    [ones(length(adaptedLeft),1);
     2*ones(length(adaptedRight),1)], ...
    'TestType','LeveneAbsolute', ...
    'Display','off');

fprintf('Baseline: p = %.4f\n', pLevBaseline);
fprintf('Adapted:  p = %.4f\n', pLevAdapted);


%% ==========================================================
% Gaussian fitting of supersubject response distributions
%
% Gaussian:
% y = A * exp(-(x-mu)^2 / (2*sigma^2))
%
% A     = amplitude / peak height
% mu    = centre of eye-contact zone
% sigma = width of eye-contact zone
% AUC   = A * sigma * sqrt(2*pi)
%
% 95% CIs obtained using participant-level bootstrap
% ==========================================================


%% ----------------------------------------------------------
% Supersubject data
% ----------------------------------------------------------

% These were already calculated above:
%
% meanX
% meanBaseline
% meanAdapted

x = meanX(:);
yBaseline = meanBaseline(:);
yAdapted  = meanAdapted(:);


%% ----------------------------------------------------------
% Gaussian function
% ----------------------------------------------------------

gaussianFun = @(params,x) ...
    params(1) .* exp(-(x-params(2)).^2 ./ ...
    (2*params(3).^2));


%% ----------------------------------------------------------
% Initial parameter estimates
% ----------------------------------------------------------

% Baseline
A0_BL = max(yBaseline);
mu0_BL = sum(x .* yBaseline) / sum(yBaseline);
sigma0_BL = std(x);

% Adapted
A0_AD = max(yAdapted);
mu0_AD = sum(x .* yAdapted) / sum(yAdapted);
sigma0_AD = std(x);


%% ----------------------------------------------------------
% Fit Gaussian to baseline
% ----------------------------------------------------------

params0_BL = [A0_BL, mu0_BL, sigma0_BL];

% Lower and upper bounds:
% amplitude >= 0
% centre within observed range
% sigma > 0

lb = [0, min(x), 0.01];
ub = [2, max(x), 100];

options = optimoptions('lsqcurvefit',...
    'Display','off');


paramsBL = lsqcurvefit( ...
    gaussianFun,...
    params0_BL,...
    x,...
    yBaseline,...
    lb,...
    ub,...
    options);


A_BL     = paramsBL(1);
mu_BL    = paramsBL(2);
sigma_BL = paramsBL(3);


%% ----------------------------------------------------------
% Fit Gaussian to adapted condition
% ----------------------------------------------------------

params0_AD = [A0_AD, mu0_AD, sigma0_AD];

paramsAD = lsqcurvefit( ...
    gaussianFun,...
    params0_AD,...
    x,...
    yAdapted,...
    lb,...
    ub,...
    options);


A_AD     = paramsAD(1);
mu_AD    = paramsAD(2);
sigma_AD = paramsAD(3);


%% ----------------------------------------------------------
% Calculate fitted values
% ----------------------------------------------------------

fitBaseline = gaussianFun(paramsBL,x);
fitAdapted  = gaussianFun(paramsAD,x);


%% ----------------------------------------------------------
% Calculate R-squared
% ----------------------------------------------------------

SSE_BL = sum((yBaseline-fitBaseline).^2);
SST_BL = sum((yBaseline-mean(yBaseline)).^2);

R2_BL = 1 - SSE_BL/SST_BL;


SSE_AD = sum((yAdapted-fitAdapted).^2);
SST_AD = sum((yAdapted-mean(yAdapted)).^2);

R2_AD = 1 - SSE_AD/SST_AD;


%% ----------------------------------------------------------
% Calculate AUC
% ----------------------------------------------------------

AUC_BL = A_BL * sigma_BL * sqrt(2*pi);
AUC_AD = A_AD * sigma_AD * sqrt(2*pi);


%% ----------------------------------------------------------
% Display point estimates
% ----------------------------------------------------------

fprintf('\n');
fprintf('====================================================\n');
fprintf('Gaussian Fits to Supersubject Response Data\n');
fprintf('====================================================\n');

fprintf('\nBASELINE\n');
fprintf('Amplitude (A) = %.3f\n',A_BL);
fprintf('Centre (mu)    = %.3f cm\n',mu_BL);
fprintf('SD (sigma)     = %.3f cm\n',sigma_BL);
fprintf('AUC            = %.3f cm\n',AUC_BL);
fprintf('R-squared      = %.4f (%.2f%% variance explained)\n',...
    R2_BL,R2_BL*100);


fprintf('\nADAPTED\n');
fprintf('Amplitude (A) = %.3f\n',A_AD);
fprintf('Centre (mu)    = %.3f cm\n',mu_AD);
fprintf('SD (sigma)     = %.3f cm\n',sigma_AD);
fprintf('AUC            = %.3f cm\n',AUC_AD);
fprintf('R-squared      = %.4f (%.2f%% variance explained)\n',...
    R2_AD,R2_AD*100);


%% ----------------------------------------------------------
% Differences between conditions
% ----------------------------------------------------------

delta_mu = mu_AD - mu_BL;
delta_sigma = sigma_AD - sigma_BL;
delta_AUC = AUC_AD - AUC_BL;


fprintf('\n');
fprintf('----------------------------------------------------\n');
fprintf('Differences: Adapted - Baseline\n');
fprintf('----------------------------------------------------\n');

fprintf('Centre difference = %.3f cm\n',delta_mu);
fprintf('SD difference     = %.3f cm\n',delta_sigma);
fprintf('AUC difference    = %.3f cm\n',delta_AUC);


%% ==========================================================
% Plot Gaussian fits
% ==========================================================

xFine = linspace(min(x),max(x),500);

fitFineBL = gaussianFun(paramsBL,xFine);
fitFineAD = gaussianFun(paramsAD,xFine);


figure
hold on

plot(x,yBaseline,...
    'b^-',...
    'LineWidth',2,...
    'MarkerSize',7);

plot(xFine,fitFineBL,...
    'b-',...
    'LineWidth',2);

plot(x,yAdapted,...
    'r^-',...
    'LineWidth',2);

plot(xFine,fitFineAD,...
    'r-',...
    'LineWidth',2);

ylim([0 1]);

xlim([min(x)-5 max(x)+5]);

axis square

ax = gca;
ax.XAxisLocation = 'origin';

xticks(x);

labels = strcat(landmarks',...
    ' (',...
    compose('%.0f',x),...
    ')');

xticklabels(labels);

xlabel('Anatomical landmark',...
    'FontSize',12,...
    'FontName','sans serif',...
    'FontWeight','bold');

ylabel('Proportion of "Yes" Eye Contact Responses',...
    'FontSize',12,...
    'FontName','sans serif',...
    'FontWeight','bold');

legend({'Baseline data','Baseline Gaussian',...
        'Adapted data','Adapted Gaussian'},...
        'Location','northeastoutside');

set(gca,'FontSize',12,'FontName','sans serif');

box off
hold off


%% ==========================================================
% Participant-level bootstrap confidence intervals
%
% Bootstrap participants while keeping the stimulus/landmark
% coordinate system fixed.
% ==========================================================

nBoot = 5000;
nParticipants = size(alignedBaseline,2);

% Fixed supersubject x-axis
bootX = meanX;

% Store bootstrap estimates
boot_mu_BL    = nan(nBoot,1);
boot_sigma_BL = nan(nBoot,1);
boot_AUC_BL   = nan(nBoot,1);

boot_mu_AD    = nan(nBoot,1);
boot_sigma_AD = nan(nBoot,1);
boot_AUC_AD   = nan(nBoot,1);

for b = 1:nBoot

    % ------------------------------------------------------
    % Resample participants with replacement
    % ------------------------------------------------------

    bootIdx = randi(nParticipants,1,nParticipants);

    % Supersubject response distributions
    bootBaseline = mean(alignedBaseline(:,bootIdx),2);
    bootAdapted  = mean(alignedAdapted(:,bootIdx),2);


    % ======================================================
    % BASELINE
    % ======================================================

    A0 = max(bootBaseline);

    mu0 = sum(bootX .* bootBaseline) / ...
          sum(bootBaseline);

    sigma0 = sqrt( ...
        sum(bootBaseline .* ...
        (bootX-mu0).^2) / ...
        sum(bootBaseline));

    params0 = [A0 mu0 sigma0];

    try

        params = lsqcurvefit( ...
            gaussianFun,...
            params0,...
            bootX,...
            bootBaseline,...
            lb,...
            ub,...
            options);

        A = params(1);
        boot_mu_BL(b) = params(2);
        boot_sigma_BL(b) = params(3);

        boot_AUC_BL(b) = ...
            A * boot_sigma_BL(b) * sqrt(2*pi);

    catch

        continue

    end


    % ======================================================
    % ADAPTED
    % ======================================================

    A0 = max(bootAdapted);

    mu0 = sum(bootX .* bootAdapted) / ...
          sum(bootAdapted);

    sigma0 = sqrt( ...
        sum(bootAdapted .* ...
        (bootX-mu0).^2) / ...
        sum(bootAdapted));

    params0 = [A0 mu0 sigma0];

    try

        params = lsqcurvefit( ...
            gaussianFun,...
            params0,...
            bootX,...
            bootAdapted,...
            lb,...
            ub,...
            options);

        A = params(1);
        boot_mu_AD(b) = params(2);
        boot_sigma_AD(b) = params(3);

        boot_AUC_AD(b) = ...
            A * boot_sigma_AD(b) * sqrt(2*pi);

    catch

        continue

    end

end


%% ==========================================================
% Remove failed bootstrap iterations
% ==========================================================

valid = ...
    ~isnan(boot_mu_BL) & ...
    ~isnan(boot_sigma_BL) & ...
    ~isnan(boot_AUC_BL) & ...
    ~isnan(boot_mu_AD) & ...
    ~isnan(boot_sigma_AD) & ...
    ~isnan(boot_AUC_AD);

boot_mu_BL    = boot_mu_BL(valid);
boot_sigma_BL = boot_sigma_BL(valid);
boot_AUC_BL   = boot_AUC_BL(valid);

boot_mu_AD    = boot_mu_AD(valid);
boot_sigma_AD = boot_sigma_AD(valid);
boot_AUC_AD   = boot_AUC_AD(valid);


%% ==========================================================
% Bootstrap differences
% ==========================================================

boot_delta_mu = ...
    boot_mu_AD - boot_mu_BL;

boot_delta_sigma = ...
    boot_sigma_AD - boot_sigma_BL;

boot_delta_AUC = ...
    boot_AUC_AD - boot_AUC_BL;


%% ==========================================================
% 95% percentile confidence intervals
% ==========================================================

CI_mu_BL = prctile(boot_mu_BL,[2.5 97.5]);
CI_sigma_BL = prctile(boot_sigma_BL,[2.5 97.5]);
CI_AUC_BL = prctile(boot_AUC_BL,[2.5 97.5]);

CI_mu_AD = prctile(boot_mu_AD,[2.5 97.5]);
CI_sigma_AD = prctile(boot_sigma_AD,[2.5 97.5]);
CI_AUC_AD = prctile(boot_AUC_AD,[2.5 97.5]);

CI_delta_mu = ...
    prctile(boot_delta_mu,[2.5 97.5]);

CI_delta_sigma = ...
    prctile(boot_delta_sigma,[2.5 97.5]);

CI_delta_AUC = ...
    prctile(boot_delta_AUC,[2.5 97.5]);


%% ==========================================================
% Final results
% ==========================================================

fprintf('\n');
fprintf('====================================================\n');
fprintf('Gaussian Parameter Estimates with 95%% CIs\n');
fprintf('====================================================\n');

fprintf('\nBASELINE\n');

fprintf('Centre (mu): %.3f cm [%.3f, %.3f]\n',...
    mu_BL,CI_mu_BL(1),CI_mu_BL(2));

fprintf('SD (sigma):  %.3f cm [%.3f, %.3f]\n',...
    sigma_BL,CI_sigma_BL(1),CI_sigma_BL(2));

fprintf('AUC:         %.3f [%.3f, %.3f]\n',...
    AUC_BL,CI_AUC_BL(1),CI_AUC_BL(2));

fprintf('R-squared:   %.4f (%.2f%%)\n',...
    R2_BL,R2_BL*100);


fprintf('\nADAPTED\n');

fprintf('Centre (mu): %.3f cm [%.3f, %.3f]\n',...
    mu_AD,CI_mu_AD(1),CI_mu_AD(2));

fprintf('SD (sigma):  %.3f cm [%.3f, %.3f]\n',...
    sigma_AD,CI_sigma_AD(1),CI_sigma_AD(2));

fprintf('AUC:         %.3f [%.3f, %.3f]\n',...
    AUC_AD,CI_AUC_AD(1),CI_AUC_AD(2));

fprintf('R-squared:   %.4f (%.2f%%)\n',...
    R2_AD,R2_AD*100);


fprintf('\n');
fprintf('----------------------------------------------------\n');
fprintf('ADAPTED - BASELINE\n');
fprintf('----------------------------------------------------\n');

fprintf('Centre difference: %.3f cm [%.3f, %.3f]\n',...
    delta_mu,...
    CI_delta_mu(1),...
    CI_delta_mu(2));

fprintf('SD difference:     %.3f cm [%.3f, %.3f]\n',...
    delta_sigma,...
    CI_delta_sigma(1),...
    CI_delta_sigma(2));

fprintf('AUC difference:    %.3f [%.3f, %.3f]\n',...
    delta_AUC,...
    CI_delta_AUC(1),...
    CI_delta_AUC(2));


fprintf('\nSuccessful bootstrap samples: %d / %d (%.1f%%)\n',...
    length(boot_mu_BL),...
    nBoot,...
    100*length(boot_mu_BL)/nBoot);

if length(boot_mu_BL) < 0.95*nBoot
    warning('More than 5%% of bootstrap iterations failed.');
end


%% ==========================================================
% Q-Q Plot Assumption Checks
% ==========================================================

%% Paired t-test
% Normality is assessed on the paired difference scores:
% Adapted - Baseline

figure

qqplot(centroidShift)

title('Q-Q Plot: Centroid Shift')

xlabel('Theoretical Quantiles')
ylabel('Observed Quantiles')

set(gca,...
    'FontSize',10,...
    'FontName','sans serif');

box off


%% ==========================================================
% Centroid shift analysis
% Wilcoxon signed-rank test
% ==========================================================

baselineCentroid = centroidAll(1,:);
adaptedCentroid  = centroidAll(2,:);

% ----------------------------------------------------------
% Align direction
%
% Condition 1 = Adapt Left
% Condition 2 = Adapt Right
%
% Left adaptation is flipped so that positive values
% represent movement toward the adapted direction.
% ----------------------------------------------------------

baselineRecoded = baselineCentroid;
adaptedRecoded  = adaptedCentroid;

idxLeft  = condition_map == 1;
idxRight = condition_map == 2;

% Flip LEFT adaptation
baselineRecoded(idxLeft) = -baselineRecoded(idxLeft);
adaptedRecoded(idxLeft)  = -adaptedRecoded(idxLeft);

% Right adaptation remains unchanged


% ----------------------------------------------------------
% Difference scores
% ----------------------------------------------------------

centroidShift = adaptedRecoded - baselineRecoded;


% ----------------------------------------------------------
% Wilcoxon signed-rank test
% ----------------------------------------------------------

[p,h,stats] = signrank( ...
    adaptedRecoded, ...
    baselineRecoded);

%Wilconxin test effect size 13/9 edit
% ----------------------------------------------------------
% Wilcoxon signed-rank test & Effect Size
% ----------------------------------------------------------

% Note: 'method','approximate' ensures MATLAB outputs the Z-statistic 
% inside the 'stats' structure, which is needed to calculate the effect size.
[p, h, stats] = signrank( ...
    adaptedRecoded, ...
    baselineRecoded, ...
    'method', 'approximate');

% Calculate Sample Size (N)
N = length(centroidShift);

% 1. Effect Size r = Z / sqrt(N)
% (Interpretation: 0.1 = small, 0.3 = medium, 0.5 = large)
z_stat = stats.zval;
r_effect = z_stat / sqrt(N);

% 2. Matched-pairs Rank-Biserial Correlation (rc)
% (Calculates the proportion of ranks in favor of the hypothesis)
% Total possible sum of ranks = N * (N + 1) / 2
W_stat = stats.signedrank; 
total_rank_sum = (N * (N + 1)) / 2;
r_biserial = (2 * W_stat / total_rank_sum) - 1;


% ----------------------------------------------------------
% Output Results
% ----------------------------------------------------------

fprintf('\n----------------------------------------\n');
fprintf('Wilcoxon Signed-Rank Test Results\n');
fprintf('----------------------------------------\n');
fprintf('Median centroid shift = %.3f\n', median(centroidShift));
fprintf('Z-statistic          = %.3f\n', z_stat);
fprintf('p-value              = %.10f\n\n', p);

fprintf('Effect Sizes:\n');
fprintf('Standardized r (Z/sqrt(N))           = %.3f\n', r_effect);
fprintf('Rank-Biserial Correlation (r_c)     = %.3f\n', r_biserial);


% ----------------------------------------------------------
% Descriptive statistics
% ----------------------------------------------------------

meanShift   = mean(centroidShift);
sdShift     = std(centroidShift);
medianShift = median(centroidShift);


% ----------------------------------------------------------
% Output
% ----------------------------------------------------------

fprintf('\n----------------------------------------\n');
fprintf('Centroid Shift Analysis\n');
fprintf('----------------------------------------\n');

fprintf('Mean shift   = %.3f\n',meanShift);
fprintf('SD shift     = %.3f\n',sdShift);
fprintf('Median shift = %.3f\n',medianShift);

fprintf('\nWilcoxon signed-rank test:\n');
fprintf('Signed-rank statistic = %.3f\n',stats.signedrank);
fprintf('p = %.10f\n',p);


%% ==========================================================
% Descriptive statistics: Baseline vs Adapted
% Directionally aligned across Left and Right adaptation
% ==========================================================

% Median
medianBaseline = median(baselineRecoded);
medianAdapted  = median(adaptedRecoded);

% IQR
IQRBaseline = iqr(baselineRecoded);
IQRAdapted  = iqr(adaptedRecoded);

% Shift
centroidShift = adaptedRecoded - baselineRecoded;

medianShift = median(centroidShift);
IQRShift    = iqr(centroidShift);


fprintf('\n========================================\n');
fprintf('Baseline vs Adapted: Descriptive Statistics\n');
fprintf('========================================\n');

fprintf('\nBaseline:\n');
fprintf('Median = %.3f\n',medianBaseline);
fprintf('IQR    = %.3f\n',IQRBaseline);

fprintf('\nAdapted:\n');
fprintf('Median = %.3f\n',medianAdapted);
fprintf('IQR    = %.3f\n',IQRAdapted);

fprintf('\nCentroid Shift (Adapted - Baseline):\n');
fprintf('Median = %.3f\n',medianShift);
fprintf('IQR    = %.3f\n',IQRShift);



%% ==========================================================
% Baseline centroid distribution
% All participants, directionally aligned
% Boxplot + Mean ± 95% CI
% ==========================================================

figure

boxplot(baselineRecoded,...
    'Labels',{'Baseline'},...
    'Symbol','');

hold on

% Mean
meanBaseline = mean(baselineRecoded);

% Standard error
SEBaseline = std(baselineRecoded) / sqrt(length(baselineRecoded));

% 95% CI
CIBaseline = tinv(0.975,length(baselineRecoded)-1) * SEBaseline;

% Plot mean
plot(1,meanBaseline,...
    'k.',...
    'MarkerSize',15);

% Plot 95% CI error bar
errorbar(1,...
    meanBaseline,...
    CIBaseline,...
    'k',...
    'LineWidth',1.5,...
    'CapSize',10);

hold off

ylabel('Centroid Position (mm)',...
    'FontSize',12,...
    'FontName','sans serif',...
    'FontWeight','bold');

set(gca,...
    'FontSize',12,...
    'FontName','sans serif');

box off


%% ==========================================================
% Adapted centroid distribution
% All participants, directionally aligned
% Boxplot + Mean ± 95% CI
% ==========================================================

figure

boxplot(adaptedRecoded,...
    'Labels',{'Adapted'},...
    'Symbol','');

hold on

% Mean
meanAdapted = mean(adaptedRecoded);

% Standard error
SEAdapted = std(adaptedRecoded) / sqrt(length(adaptedRecoded));

% 95% CI
CIAdapted = tinv(0.975,length(adaptedRecoded)-1) * SEAdapted;

% Plot mean
plot(1,meanAdapted,...
    'k.',...
    'MarkerSize',15);

% Plot 95% CI error bar
errorbar(1,...
    meanAdapted,...
    CIAdapted,...
    'k',...
    'LineWidth',1.5,...
    'CapSize',10);

hold off

ylabel('Centroid Position (mm)',...
    'FontSize',12,...
    'FontName','sans serif',...
    'FontWeight','bold');

set(gca,...
    'FontSize',12,...
    'FontName','sans serif');

box off



%% ==========================================================
% Baseline vs Adapted Centroid Distribution
% All participants, directionally aligned
% Boxplot + Mean ± 95% CI
% ==========================================================

figure

% Combine data
centroidData = [baselineRecoded(:), adaptedRecoded(:)];

% Boxplots
boxplot(centroidData,...
    'Labels',{'Baseline','Adapted'},...
    'Symbol','');

hold on


%% ----------------------------------------------------------
% Baseline mean and 95% CI
% ----------------------------------------------------------

meanBaseline = mean(baselineRecoded);
SEBaseline = std(baselineRecoded) / sqrt(length(baselineRecoded));

CIBaseline = tinv(0.975,...
    length(baselineRecoded)-1) * SEBaseline;


%% ----------------------------------------------------------
% Adapted mean and 95% CI
% ----------------------------------------------------------

meanAdapted = mean(adaptedRecoded);
SEAdapted = std(adaptedRecoded) / sqrt(length(adaptedRecoded));

CIAdapted = tinv(0.975,...
    length(adaptedRecoded)-1) * SEAdapted;


%% ----------------------------------------------------------
% Plot means
% ----------------------------------------------------------

plot(1,meanBaseline,...
    'k.',...
    'MarkerSize',15);

plot(2,meanAdapted,...
    'k.',...
    'MarkerSize',15);


%% ----------------------------------------------------------
% Plot 95% CI error bars
% ----------------------------------------------------------

errorbar(1,...
    meanBaseline,...
    CIBaseline,...
    'k',...
    'LineWidth',1.5,...
    'CapSize',10);

errorbar(2,...
    meanAdapted,...
    CIAdapted,...
    'k',...
    'LineWidth',1.5,...
    'CapSize',10);


%% ==========================================================
% Baseline vs Adapted Centroid Distribution
% All participants, directionally aligned
% Boxplot + Mean ± 95% CI
% ==========================================================

figure

% Combine data
centroidData = [baselineRecoded(:), adaptedRecoded(:)];

% Boxplots
boxplot(centroidData,...
    'Labels',{'Baseline','Adapted'},...
    'Symbol','');

hold on


%% ----------------------------------------------------------
% Baseline mean and 95% CI
% ----------------------------------------------------------

meanBaseline = mean(baselineRecoded);
SEBaseline = std(baselineRecoded) / sqrt(length(baselineRecoded));

CIBaseline = tinv(0.975,...
    length(baselineRecoded)-1) * SEBaseline;


%% ----------------------------------------------------------
% Adapted mean and 95% CI
% ----------------------------------------------------------

meanAdapted = mean(adaptedRecoded);
SEAdapted = std(adaptedRecoded) / sqrt(length(adaptedRecoded));

CIAdapted = tinv(0.975,...
    length(adaptedRecoded)-1) * SEAdapted;


%% ----------------------------------------------------------
% Plot means
% ----------------------------------------------------------

plot(1,meanBaseline,...
    'k.',...
    'MarkerSize',15);

plot(2,meanAdapted,...
    'k.',...
    'MarkerSize',15);


%% ----------------------------------------------------------
% Plot 95% CI error bars
% ----------------------------------------------------------

errorbar(1,...
    meanBaseline,...
    CIBaseline,...
    'k',...
    'LineWidth',1.5,...
    'CapSize',10);

errorbar(2,...
    meanAdapted,...
    CIAdapted,...
    'k',...
    'LineWidth',1.5,...
    'CapSize',10);


%% ----------------------------------------------------------
% Formatting
% ----------------------------------------------------------

ylabel('Centroid Position (mm)',...
    'FontSize',12,...
    'FontName','sans serif',...
    'FontWeight','bold');

set(gca,...
    'FontSize',12,...
    'FontName','sans serif');

box off

hold off



%% ==========================================================
% Baseline vs Adapted Centroid Distribution
% Horizontal boxplots
% X-axis = Centroid Position
% All participants, directionally aligned
% ==========================================================

figure

% Combine participant-level centroid data
centroidData = [baselineRecoded(:), adaptedRecoded(:)];

% Horizontal boxplot
boxplot(centroidData, ...
    'Orientation','horizontal', ...
    'Labels',{'Baseline','Adapted'}, ...
    'Symbol','');

hold on

%% ----------------------------------------------------------
% Calculate means
% ----------------------------------------------------------

meanBaseline = mean(baselineRecoded);
meanAdapted  = mean(adaptedRecoded);

%% ----------------------------------------------------------
% Calculate 95% confidence intervals
% ----------------------------------------------------------

SEBaseline = std(baselineRecoded) / sqrt(numel(baselineRecoded));
SEAdapted  = std(adaptedRecoded) / sqrt(numel(adaptedRecoded));

CIBaseline = tinv(0.975, numel(baselineRecoded)-1) * SEBaseline;
CIAdapted  = tinv(0.975, numel(adaptedRecoded)-1) * SEAdapted;

%% ----------------------------------------------------------
% Plot means
% ----------------------------------------------------------

plot(meanBaseline, 1, ...
    'k.', ...
    'MarkerSize',15);

plot(meanAdapted, 2, ...
    'k.', ...
    'MarkerSize',15);

%% ----------------------------------------------------------
% Manually plot horizontal 95% confidence intervals
% Do not use horizontal errorbar
% ----------------------------------------------------------

% Baseline horizontal confidence interval
plot([meanBaseline-CIBaseline, meanBaseline+CIBaseline], ...
     [1 1], ...
     'k-', ...
     'LineWidth',1.5);

% Adapted horizontal confidence interval
plot([meanAdapted-CIAdapted, meanAdapted+CIAdapted], ...
     [2 2], ...
     'k-', ...
     'LineWidth',1.5);

%% ----------------------------------------------------------
% Add vertical caps
% ----------------------------------------------------------

capHeight = 0.08;

% Baseline left cap
plot([meanBaseline-CIBaseline, meanBaseline-CIBaseline], ...
     [1-capHeight, 1+capHeight], ...
     'k-', ...
     'LineWidth',1.5);

% Baseline right cap
plot([meanBaseline+CIBaseline, meanBaseline+CIBaseline], ...
     [1-capHeight, 1+capHeight], ...
     'k-', ...
     'LineWidth',1.5);

% Adapted left cap
plot([meanAdapted-CIAdapted, meanAdapted-CIAdapted], ...
     [2-capHeight, 2+capHeight], ...
     'k-', ...
     'LineWidth',1.5);

% Adapted right cap
plot([meanAdapted+CIAdapted, meanAdapted+CIAdapted], ...
     [2-capHeight, 2+capHeight], ...
     'k-', ...
     'LineWidth',1.5);

%% ----------------------------------------------------------
% Formatting
% ----------------------------------------------------------

xlabel('Centroid Position(mm)', ...
    'FontSize',12, ...
    'FontName','sans serif', ...
    'FontWeight','bold');

ylabel('Condition', ...
    'FontSize',12, ...
    'FontName','sans serif', ...
    'FontWeight','bold');

title('Participant-level Centroid Distributions');

set(gca, ...
    'FontSize',12, ...
    'FontName','sans serif');

box off
hold off


%% ==========================================================
% Baseline vs Adapted Centroid Distribution
% Horizontal boxplots + individual participant centroids
% ==========================================================

figure

% Combine participant-level centroid data
centroidData = [baselineRecoded(:), adaptedRecoded(:)];

% Horizontal boxplot
boxplot(centroidData, ...
    'Orientation','horizontal', ...
    'Labels',{'Baseline','Adapted'}, ...
    'Symbol','');

hold on

%% ----------------------------------------------------------
% Plot individual participant centroids
% Baseline = blue
% Adapted = red
%% ----------------------------------------------------------

nParticipants = numel(baselineRecoded);

% Small vertical jitter so overlapping dots remain visible
jitterAmount = 0.08;

baselineY = 1 + (rand(nParticipants,1)-0.5) * jitterAmount;
adaptedY  = 2 + (rand(nParticipants,1)-0.5) * jitterAmount;

plot(baselineRecoded, baselineY, ...
    '.', ...
    'Color',[0 0.4470 0.7410], ...
    'MarkerSize',14);

plot(adaptedRecoded, adaptedY, ...
    '.', ...
    'Color',[0.8500 0.3250 0.0980], ...
    'MarkerSize',14);

%% ----------------------------------------------------------
% Calculate means
%% ----------------------------------------------------------

meanBaseline = mean(baselineRecoded);
meanAdapted  = mean(adaptedRecoded);

%% ----------------------------------------------------------
% Calculate 95% confidence intervals
%% ----------------------------------------------------------

SEBaseline = std(baselineRecoded) / sqrt(numel(baselineRecoded));
SEAdapted  = std(adaptedRecoded) / sqrt(numel(adaptedRecoded));

CIBaseline = tinv(0.975, numel(baselineRecoded)-1) * SEBaseline;
CIAdapted  = tinv(0.975, numel(adaptedRecoded)-1) * SEAdapted;

%% ----------------------------------------------------------
% Plot means as black dots
%% ----------------------------------------------------------

plot(meanBaseline, 1, ...
    'k.', ...
    'MarkerSize',20);

plot(meanAdapted, 2, ...
    'k.', ...
    'MarkerSize',20);

%% ----------------------------------------------------------
% Plot horizontal 95% confidence intervals
%% ----------------------------------------------------------

plot([meanBaseline-CIBaseline, meanBaseline+CIBaseline], ...
     [1 1], ...
     'k-', ...
     'LineWidth',1.5);

plot([meanAdapted-CIAdapted, meanAdapted+CIAdapted], ...
     [2 2], ...
     'k-', ...
     'LineWidth',1.5);

%% ----------------------------------------------------------
% Add vertical CI caps
%% ----------------------------------------------------------

capHeight = 0.08;

plot([meanBaseline-CIBaseline, meanBaseline-CIBaseline], ...
     [1-capHeight, 1+capHeight], ...
     'k-', ...
     'LineWidth',1.5);

plot([meanBaseline+CIBaseline, meanBaseline+CIBaseline], ...
     [1-capHeight, 1+capHeight], ...
     'k-', ...
     'LineWidth',1.5);

plot([meanAdapted-CIAdapted, meanAdapted-CIAdapted], ...
     [2-capHeight, 2+capHeight], ...
     'k-', ...
     'LineWidth',1.5);

plot([meanAdapted+CIAdapted, meanAdapted+CIAdapted], ...
     [2-capHeight, 2+capHeight], ...
     'k-', ...
     'LineWidth',1.5);

%% ----------------------------------------------------------
% Formatting
%% ----------------------------------------------------------

xlabel('Centroid Position (mm)', ...
    'FontSize',12, ...
    'FontName','sans serif', ...
    'FontWeight','bold');

ylabel('Condition', ...
    'FontSize',12, ...
    'FontName','sans serif', ...
    'FontWeight','bold');

title('Participant-level Centroid Distributions');

set(gca, ...
    'FontSize',12, ...
    'FontName','sans serif');

box off
hold off

%% ========================================================== LATEST ADD ON 18 SEPT.
% Recolour Baseline vs Adapted Boxplot
% Baseline = Blue
% Adapted  = Red
% Remove Y-axis labels
% ==========================================================

ax = gca;

% ----------------------------------------------------------
% Find all boxplot line objects
% ----------------------------------------------------------

h = findobj(ax, 'Tag', 'Box');

% MATLAB returns the boxes in reverse order
% so sort them according to their x-position
boxX = zeros(length(h),1);

for i = 1:length(h)
    xData = get(h(i),'XData');
    boxX(i) = mean(xData);
end

[~, order] = sort(boxX);
h = h(order);

% ----------------------------------------------------------
% Colour the boxes
% Box 1 = Baseline
% Box 2 = Adapted
% ----------------------------------------------------------

if length(h) >= 2

    % Baseline = blue
    set(h(1), ...
        'Color',[0 0.4470 0.7410], ...
        'LineWidth',1.5);

    % Adapted = red
    set(h(2), ...
        'Color',[0.8500 0.3250 0.0980], ...
        'LineWidth',1.5);

end

% ----------------------------------------------------------
% Also colour the median lines
% ----------------------------------------------------------

med = findobj(ax, 'Tag', 'Median');

medX = zeros(length(med),1);

for i = 1:length(med)
    xData = get(med(i),'XData');
    medX(i) = mean(xData);
end

[~, order] = sort(medX);
med = med(order);

if length(med) >= 2

    % Baseline median = blue
    set(med(1), ...
        'Color',[0 0.4470 0.7410], ...
        'LineWidth',2);

    % Adapted median = red
    set(med(2), ...
        'Color',[0.8500 0.3250 0.0980], ...
        'LineWidth',2);

end

% ----------------------------------------------------------
% Remove Y-axis labels
% ----------------------------------------------------------

yticklabels({});

% ----------------------------------------------------------
% Create legend
% ----------------------------------------------------------

hold on

hBaseline = plot(nan,nan,'-', ...
    'Color',[0 0.4470 0.7410], ...
    'LineWidth',2);

hAdapted = plot(nan,nan,'-', ...
    'Color',[0.8500 0.3250 0.0980], ...
    'LineWidth',2);

legend([hBaseline hAdapted], ...
    {'Baseline','Adapted'}, ...
    'Location','best', ...
    'FontSize', 18);

hold off


%axes width and font

legend([hBaseline hAdapted], ...
    {'Baseline','Adapted'}, ...
    'Location','best');

set(gca, 'FontSize', 18);

hold off

xlabel('Centroid Position (mm)', ...
    'FontSize', 18, ...
    'FontWeight', 'bold');






%% ==========================================================
% Horizontal Boxplots + Individual Participant Centroids
% Separately by Adaptation Direction
%
% X-axis = Centroid Position
% Y-axis = Condition (Baseline, Adapted)
%
% Baseline = Blue
% Adapted  = Orange/Red
% Individual dots = Participants
% Circle = Mean centroid (BLACK)
% Black horizontal error bars = 95% CI
% Font = Arial (sans-serif), maximum size 14
%
% IMPORTANT:
% Leftward condition is NOT recoded.
% Both conditions use their original centroid values.
% ==========================================================

blue   = [0 0.4470 0.7410];
orange = [0.8500 0.3250 0.0980];

rng(1);

jitterAmount = 0.10;
dotSize = 35;
fontName = 'Arial';
fontSize = 14;

%% ==========================================================
% LEFTWARD ADAPTATION CONDITION
% condition_map == 1
% ==========================================================

idxLeft = condition_map == 1;

% Use ORIGINAL centroid values: no directional recoding
baselineLeft = baselineCentroid(idxLeft);
adaptedLeft  = adaptedCentroid(idxLeft);

% Remove missing/non-finite values independently
baselineLeft = baselineLeft(isfinite(baselineLeft));
adaptedLeft  = adaptedLeft(isfinite(adaptedLeft));

% Prepare boxplot data
nMaxLeft = max(numel(baselineLeft), numel(adaptedLeft));

plotLeft = NaN(nMaxLeft, 2);
plotLeft(1:numel(baselineLeft),1) = baselineLeft;
plotLeft(1:numel(adaptedLeft),2)  = adaptedLeft;

% Means and 95% confidence intervals
nBL = numel(baselineLeft);
nAL = numel(adaptedLeft);

meanBL = mean(baselineLeft);
meanAL = mean(adaptedLeft);

ciBL = NaN;
ciAL = NaN;

if nBL >= 2
    ciBL = tinv(0.975,nBL-1) * std(baselineLeft) / sqrt(nBL);
end

if nAL >= 2
    ciAL = tinv(0.975,nAL-1) * std(adaptedLeft) / sqrt(nAL);
end

figure('Color','w');
hold on;

boxplot(plotLeft, ...
    'Orientation','horizontal', ...
    'Labels',{'Baseline','Adapted'}, ...
    'Symbol','');

title('Leftward Adaptation', ...
    'FontName',fontName,'FontSize',fontSize);

ax = gca;

% ----------------------------------------------------------
% Recolour boxes
% ----------------------------------------------------------

h = findobj(ax,'Tag','Box');
boxY = zeros(length(h),1);

for i = 1:length(h)
    yData = get(h(i),'YData');
    boxY(i) = mean(yData);
end

[~,order] = sort(boxY);
h = h(order);

if length(h) >= 2
    set(h(1),'Color',blue,'LineWidth',1.5);
    set(h(2),'Color',orange,'LineWidth',1.5);
end

% ----------------------------------------------------------
% Recolour median lines
% ----------------------------------------------------------

med = findobj(ax,'Tag','Median');
medY = zeros(length(med),1);

for i = 1:length(med)
    yData = get(med(i),'YData');
    medY(i) = mean(yData);
end

[~,order] = sort(medY);
med = med(order);

if length(med) >= 2
    set(med(1),'Color',blue,'LineWidth',2);
    set(med(2),'Color',orange,'LineWidth',2);
end

% ----------------------------------------------------------
% Individual participant centroids
% ----------------------------------------------------------

scatter(baselineLeft, ...
    1 + (rand(size(baselineLeft))-0.5)*2*jitterAmount, ...
    dotSize,blue,'filled', ...
    'MarkerFaceAlpha',0.75, ...
    'MarkerEdgeColor','none');

scatter(adaptedLeft, ...
    2 + (rand(size(adaptedLeft))-0.5)*2*jitterAmount, ...
    dotSize,orange,'filled', ...
    'MarkerFaceAlpha',0.75, ...
    'MarkerEdgeColor','none');

% ----------------------------------------------------------
% Black horizontal 95% confidence intervals
% ----------------------------------------------------------

if nBL >= 2
    errorbar(meanBL,1,ciBL,ciBL,'horizontal', ...
        'Color','k','LineWidth',2,'CapSize',8, ...
        'HandleVisibility','off');
end

if nAL >= 2
    errorbar(meanAL,2,ciAL,ciAL,'horizontal', ...
        'Color','k','LineWidth',2,'CapSize',8, ...
        'HandleVisibility','off');
end

% ----------------------------------------------------------
% MEAN MARKERS: BLACK CIRCLES
% ----------------------------------------------------------

if nBL >= 1
    plot(meanBL,1,'ko', ...
        'MarkerSize',7, ...
        'MarkerFaceColor','k', ...
        'MarkerEdgeColor','k', ...
        'HandleVisibility','off');
end

if nAL >= 1
    plot(meanAL,2,'ko', ...
        'MarkerSize',7, ...
        'MarkerFaceColor','k', ...
        'MarkerEdgeColor','k', ...
        'HandleVisibility','off');
end

% ----------------------------------------------------------
% Formatting
% ----------------------------------------------------------

yticks([1 2]);
yticklabels({'Baseline','Adapted'});

xlabel('Centroid Position (mm)', ...
    'FontName',fontName,'FontSize',fontSize,'FontWeight','bold');

ylabel('Condition', ...
    'FontName',fontName,'FontSize',fontSize,'FontWeight','bold');

set(gca,'FontName',fontName,'FontSize',fontSize);
ylim([0.5 2.5]);
box on;

% Legend: Baseline and Adapted only
hBaseline = plot(nan,nan,'-', ...
    'Color',blue,'LineWidth',2);

hAdapted = plot(nan,nan,'-', ...
    'Color',orange,'LineWidth',2);

lgd = legend([hBaseline hAdapted], ...
    {'Baseline','Adapted'}, ...
    'Location','best');

set(lgd,'FontName',fontName,'FontSize',fontSize);

hold off;


%% ==========================================================
% RIGHTWARD ADAPTATION CONDITION
% condition_map == 2
% ==========================================================

idxRight = condition_map == 2;

% Use ORIGINAL centroid values: no directional recoding
baselineRight = baselineCentroid(idxRight);
adaptedRight  = adaptedCentroid(idxRight);

% Remove missing/non-finite values independently
baselineRight = baselineRight(isfinite(baselineRight));
adaptedRight  = adaptedRight(isfinite(adaptedRight));

% Prepare boxplot data
nMaxRight = max(numel(baselineRight), numel(adaptedRight));

plotRight = NaN(nMaxRight, 2);
plotRight(1:numel(baselineRight),1) = baselineRight;
plotRight(1:numel(adaptedRight),2)  = adaptedRight;

% Means and 95% confidence intervals
nBR = numel(baselineRight);
nAR = numel(adaptedRight);

meanBR = mean(baselineRight);
meanAR = mean(adaptedRight);

ciBR = NaN;
ciAR = NaN;

if nBR >= 2
    ciBR = tinv(0.975,nBR-1) * std(baselineRight) / sqrt(nBR);
end

if nAR >= 2
    ciAR = tinv(0.975,nAR-1) * std(adaptedRight) / sqrt(nAR);
end

figure('Color','w');
hold on;

boxplot(plotRight, ...
    'Orientation','horizontal', ...
    'Labels',{'Baseline','Adapted'}, ...
    'Symbol','');

title('Rightward Adaptation', ...
    'FontName',fontName,'FontSize',fontSize);

ax = gca;

% ----------------------------------------------------------
% Recolour boxes
% ----------------------------------------------------------

h = findobj(ax,'Tag','Box');
boxY = zeros(length(h),1);

for i = 1:length(h)
    yData = get(h(i),'YData');
    boxY(i) = mean(yData);
end

[~,order] = sort(boxY);
h = h(order);

if length(h) >= 2
    set(h(1),'Color',blue,'LineWidth',1.5);
    set(h(2),'Color',orange,'LineWidth',1.5);
end

% ----------------------------------------------------------
% Recolour median lines
% ----------------------------------------------------------

med = findobj(ax,'Tag','Median');
medY = zeros(length(med),1);

for i = 1:length(med)
    yData = get(med(i),'YData');
    medY(i) = mean(yData);
end

[~,order] = sort(medY);
med = med(order);

if length(med) >= 2
    set(med(1),'Color',blue,'LineWidth',2);
    set(med(2),'Color',orange,'LineWidth',2);
end

% ----------------------------------------------------------
% Individual participant centroids
% ----------------------------------------------------------

scatter(baselineRight, ...
    1 + (rand(size(baselineRight))-0.5)*2*jitterAmount, ...
    dotSize,blue,'filled', ...
    'MarkerFaceAlpha',0.75, ...
    'MarkerEdgeColor','none');

scatter(adaptedRight, ...
    2 + (rand(size(adaptedRight))-0.5)*2*jitterAmount, ...
    dotSize,orange,'filled', ...
    'MarkerFaceAlpha',0.75, ...
    'MarkerEdgeColor','none');

% ----------------------------------------------------------
% Black horizontal 95% confidence intervals
% ----------------------------------------------------------

if nBR >= 2
    errorbar(meanBR,1,ciBR,ciBR,'horizontal', ...
        'Color','k','LineWidth',2,'CapSize',8, ...
        'HandleVisibility','off');
end

if nAR >= 2
    errorbar(meanAR,2,ciAR,ciAR,'horizontal', ...
        'Color','k','LineWidth',2,'CapSize',8, ...
        'HandleVisibility','off');
end

% ----------------------------------------------------------
% MEAN MARKERS: BLACK CIRCLES
% ----------------------------------------------------------

if nBR >= 1
    plot(meanBR,1,'ko', ...
        'MarkerSize',7, ...
        'MarkerFaceColor','k', ...
        'MarkerEdgeColor','k', ...
        'HandleVisibility','off');
end

if nAR >= 1
    plot(meanAR,2,'ko', ...
        'MarkerSize',7, ...
        'MarkerFaceColor','k', ...
        'MarkerEdgeColor','k', ...
        'HandleVisibility','off');
end

% ----------------------------------------------------------
% Formatting
% ----------------------------------------------------------

yticks([1 2]);
yticklabels({'Baseline','Adapted'});

xlabel('Centroid Position (mm)', ...
    'FontName',fontName,'FontSize',fontSize,'FontWeight','bold');

ylabel('Condition', ...
    'FontName',fontName,'FontSize',fontSize,'FontWeight','bold');

set(gca,'FontName',fontName,'FontSize',fontSize);
ylim([0.5 2.5]);
box on;

% Legend: Baseline and Adapted only
hBaseline = plot(nan,nan,'-', ...
    'Color',blue,'LineWidth',2);

hAdapted = plot(nan,nan,'-', ...
    'Color',orange,'LineWidth',2);

lgd = legend([hBaseline hAdapted], ...
    {'Baseline','Adapted'}, ...
    'Location','best');

set(lgd,'FontName',fontName,'FontSize',fontSize);

hold off;



%% SIMPLE EFFECTS / INTERACTION PLOT
% 2 x 2 mixed ANOVA:
% Within-subject factor: Aftereffect (Baseline vs Adapted)
% Between-subject factor: Direction (Left vs Right adaptation)
%
% Uses directionally recoded centroid values.
% Error bars show 95% confidence intervals for each group mean.

% Ensure column vectors
baselinePlot = baselineRecoded(:);
adaptedPlot  = adaptedRecoded(:);
directionPlot = condition_map(:);

% Keep participants with valid paired data and known direction
validPlot = isfinite(baselinePlot) & ...
            isfinite(adaptedPlot) & ...
            ismember(directionPlot, [1 2]);

baselinePlot = baselinePlot(validPlot);
adaptedPlot  = adaptedPlot(validPlot);
directionPlot = directionPlot(validPlot);

% X-axis positions
x = [1 2];

% Group definitions:
% 1 = Left adaptation
% 2 = Right adaptation
groups = [1 2];
groupNames = {'Left adaptation', 'Right adaptation'};

figure('Color', 'w', 'Name', ...
    'Simple Effects - Experiment 2');

hold on;

for g = groups

    % Select participants in this adaptation group
    idx = directionPlot == g;

    % Means at Baseline and Adapted
    baselineValues = baselinePlot(idx);
    adaptedValues  = adaptedPlot(idx);

    n = sum(idx);

    if n < 2
        warning('Group %d has fewer than 2 valid participants.', g);
        continue;
    end

    means = [mean(baselineValues), mean(adaptedValues)];

    % Standard errors
    sem = [std(baselineValues, 0) / sqrt(n), ...
           std(adaptedValues, 0) / sqrt(n)];

    % 95% t-based confidence intervals
    tCrit = tinv(0.975, n - 1);
    ci = tCrit .* sem;

    % Plot means and confidence intervals
    errorbar(x, means, ci, 'o-', ...
        'LineWidth', 1.8, ...
        'MarkerSize', 7, ...
        'CapSize', 10, ...
        'DisplayName', groupNames{g});

    % Print descriptive statistics
    fprintf('\n%s (n = %d)\n', groupNames{g}, n);
    fprintf('Baseline: M = %.4f, 95%% CI [%.4f, %.4f]\n', ...
        means(1), means(1)-ci(1), means(1)+ci(1));
    fprintf('Adapted:  M = %.4f, 95%% CI [%.4f, %.4f]\n', ...
        means(2), means(2)-ci(2), means(2)+ci(2));
end

% Format graph
xlim([0.8 2.2]);
xticks([1 2]);
xticklabels({'Baseline', 'Adapted'});

xlabel('Aftereffect');
ylabel('Directionally recoded centroid');
title('Simple Effects of Aftereffect by Adaptation Direction');

legend('Location', 'best');
grid on;
box off;

set(gca, 'FontSize', 12, 'LineWidth', 1);
hold off;





%% ==========================================================
% 2 x 2 MIXED ANOVA + BONFERRONI POST-HOC COMPARISONS
% ORIGINAL / UNCODED CENTROID VALUES
%
% Within-subject factor: Aftereffect (Baseline vs Adapted)
% Between-subject factor: Direction (Left vs Right adaptation)
%
% Reports:
% 1. Main effect of Aftereffect
% 2. Main effect of Direction
% 3. Aftereffect x Direction interaction
% 4. F statistics, df, p-values, partial eta squared
% 5. Four Bonferroni-corrected simple-effect comparisons
%
% Uses centroidAll directly. NO directional recoding.
% Requires Statistics and Machine Learning Toolbox.
% ==========================================================

%% ----------------------------------------------------------
% 1. Prepare original, uncoded data
% ----------------------------------------------------------

baselineUncoded = centroidAll(1,:)';
adaptedUncoded  = centroidAll(2,:)';
directionUncoded = condition_map(:);

% Include participants with valid paired data and known direction
valid = isfinite(baselineUncoded) & ...
        isfinite(adaptedUncoded) & ...
        ismember(directionUncoded,[1 2]);

baselineUncoded  = baselineUncoded(valid);
adaptedUncoded   = adaptedUncoded(valid);
directionUncoded = directionUncoded(valid);

% Group indicators
idxLeft  = directionUncoded == 1;
idxRight = directionUncoded == 2;


%% ==========================================================
% PLANNED CONTRASTS: CENTROID SHIFT WITHIN EACH DIRECTION
% Original / uncoded centroid values
%
% Leftward adaptation:  condition_map == 1
% Rightward adaptation: condition_map == 2
%
% Reports:
% 1. Mean centroid shift (Adapted - Baseline)
% 2. SD of individual centroid shifts
% 3. Paired-samples t-test
% 4. Cohen's dz
% 5. 95% CI for the mean shift
% 6. Bonferroni correction for two planned tests
% ==========================================================

% Individual centroid shifts: no directional recoding
shiftUncoded = adaptedUncoded - baselineUncoded;

% Separate groups
shiftLeft  = shiftUncoded(idxLeft);
shiftRight = shiftUncoded(idxRight);

% Remove any non-finite observations
shiftLeft  = shiftLeft(isfinite(shiftLeft));
shiftRight = shiftRight(isfinite(shiftRight));

% Planned contrasts: is mean shift different from zero?
[~, pLeft, ciLeft, statsLeft] = ttest(shiftLeft, 0);
[~, pRight, ciRight, statsRight] = ttest(shiftRight, 0);

% Cohen's dz for paired-samples comparisons
dZ_Left  = mean(shiftLeft)  / std(shiftLeft, 0);
dZ_Right = mean(shiftRight) / std(shiftRight, 0);

% Bonferroni correction for the two planned tests
pLeftBonf  = min(pLeft * 2, 1);
pRightBonf = min(pRight * 2, 1);
alphaBonf = 0.05 / 2;

% Display results
fprintf('\n==================================================\n');
fprintf('PLANNED CONTRASTS: CENTROID SHIFT BY DIRECTION\n');
fprintf('Shift = Adapted centroid - Baseline centroid\n');
fprintf('==================================================\n');

fprintf('\nLEFTWARD ADAPTATION (n = %d)\n', numel(shiftLeft));
fprintf('Mean shift = %.4f\n', mean(shiftLeft));
fprintf('SD of shift = %.4f\n', std(shiftLeft, 0));
fprintf('95%% CI = [%.4f, %.4f]\n', ciLeft(1), ciLeft(2));
fprintf('t(%d) = %.4f\n', statsLeft.df, statsLeft.tstat);
fprintf('Raw p = %.6f\n', pLeft);
fprintf('Bonferroni-adjusted p = %.6f\n', pLeftBonf);
fprintf('Cohen''s dz = %.4f\n', dZ_Left);

fprintf('\nRIGHTWARD ADAPTATION (n = %d)\n', numel(shiftRight));
fprintf('Mean shift = %.4f\n', mean(shiftRight));
fprintf('SD of shift = %.4f\n', std(shiftRight, 0));
fprintf('95%% CI = [%.4f, %.4f]\n', ciRight(1), ciRight(2));
fprintf('t(%d) = %.4f\n', statsRight.df, statsRight.tstat);
fprintf('Raw p = %.6f\n', pRight);
fprintf('Bonferroni-adjusted p = %.6f\n', pRightBonf);
fprintf('Cohen''s dz = %.4f\n', dZ_Right);

fprintf('\nBonferroni-adjusted significance threshold = %.3f\n', ...
    alphaBonf);
fprintf('==================================================\n');



%% ----------------------------------------------------------
% LEVENE'S TEST: HOMOGENEITY OF VARIANCES
% Left vs Right adaptation groups
% Baseline, Adapted, and Change scores
% ----------------------------------------------------------

changeUncoded = adaptedUncoded - baselineUncoded;

leveneData = {
    baselineUncoded, 'Baseline centroid';
    adaptedUncoded,  'Adapted centroid';
    changeUncoded,   'Change score (Adapted - Baseline)'
};

fprintf('\n==============================================\n');
fprintf('LEVENE''S TEST: HOMOGENEITY OF VARIANCES\n');
fprintf('==============================================\n');

for k = 1:size(leveneData, 1)

    values = leveneData{k, 1};
    testName = leveneData{k, 2};

    % Keep only valid observations in each group
    leftValues  = values(idxLeft);
    rightValues = values(idxRight);

    leftValues  = leftValues(isfinite(leftValues));
    rightValues = rightValues(isfinite(rightValues));

    % Absolute deviations from each group's median
    devLeft  = abs(leftValues  - median(leftValues));
    devRight = abs(rightValues - median(rightValues));

    % One-way ANOVA on absolute deviations
    devValues = [devLeft; devRight];

    group = [
        ones(numel(devLeft), 1);
        2 * ones(numel(devRight), 1)
    ];

    [pLev, anovaTbl] = anova1(devValues, group, 'off');

    % Extract ANOVA F statistic and degrees of freedom
    F_Levene   = anovaTbl{2, 5};
    df1_Levene = anovaTbl{2, 3};
    df2_Levene = anovaTbl{3, 3};

    fprintf('\n%s\n', testName);
    fprintf('F(%g, %g) = %.4f, p = %.6f\n', ...
        df1_Levene, df2_Levene, F_Levene, pLev);

    if pLev < 0.05
        fprintf('Result: Significant variance difference.\n');
    else
        fprintf('Result: No significant variance difference.\n');
    end
end

fprintf('\n==============================================\n');


%% ----------------------------------------------------------
% 2. Fit the mixed ANOVA
% ----------------------------------------------------------

% Each row represents one participant.
% The two measurement columns are repeated observations.
T_uncoded = table( ...
    baselineUncoded, ...
    adaptedUncoded, ...
    categorical(directionUncoded), ...
    'VariableNames',{'Baseline','Adapted','Direction'});

% Within-subject factor
Within_uncoded = table( ...
    categorical({'Baseline';'Adapted'}), ...
    'VariableNames',{'Aftereffect'});

% Fit repeated-measures model
rm_uncoded = fitrm( ...
    T_uncoded, ...
    'Baseline-Adapted ~ Direction', ...
    'WithinDesign',Within_uncoded);

% Repeated-measures ANOVA table:
% Aftereffect and Aftereffect x Direction
ranova_uncoded = ranova( ...
    rm_uncoded, ...
    'WithinModel','Aftereffect');

% Between-subject ANOVA table:
% Direction
between_uncoded = anova(rm_uncoded);

disp('Repeated-measures ANOVA table:');
disp(ranova_uncoded);

disp('Between-subject ANOVA table:');
disp(between_uncoded);

%% ----------------------------------------------------------
% 3. Extract the Aftereffect main effect
% ----------------------------------------------------------

withinRows = string(ranova_uncoded.Properties.RowNames);

idxAE = find(withinRows == "(Intercept):Aftereffect",1);
idxErrAE = find(withinRows == "Error(Aftereffect)",1);

if isempty(idxAE) || isempty(idxErrAE)
    error(['Could not identify the Aftereffect effect/error rows. ' ...
           'Inspect ranova_uncoded.Properties.RowNames.']);
end

F_AE  = ranova_uncoded.F(idxAE);
df1_AE = ranova_uncoded.DF(idxAE);
df2_AE = ranova_uncoded.DF(idxErrAE);
p_AE  = ranova_uncoded.pValue(idxAE);

eta2_AE = (F_AE * df1_AE) / ...
          (F_AE * df1_AE + df2_AE);

%% ----------------------------------------------------------
% 4. Extract the Aftereffect x Direction interaction
% ----------------------------------------------------------

idxInt = find(withinRows == "Direction:Aftereffect",1);

if isempty(idxInt)
    error(['Could not identify the Direction:Aftereffect row. ' ...
           'Inspect ranova_uncoded.Properties.RowNames.']);
end

F_Int   = ranova_uncoded.F(idxInt);
df1_Int = ranova_uncoded.DF(idxInt);
df2_Int = ranova_uncoded.DF(idxErrAE);
p_Int   = ranova_uncoded.pValue(idxInt);

eta2_Int = (F_Int * df1_Int) / ...
           (F_Int * df1_Int + df2_Int);

%% ----------------------------------------------------------
% 5. Extract the Direction main effect
% ----------------------------------------------------------


% ----------------------------------------------------------
% 5. Extract the Direction main effect
% ----------------------------------------------------------

% Display the table for verification
disp('Between-subject ANOVA table:');
disp(between_uncoded);

% Use the row order returned by anova(rm):
% Row 1 = Intercept
% Row 2 = Direction
% Row 3 = Error

F_Dir   = between_uncoded.F(2);
df1_Dir = between_uncoded.DF(2);
p_Dir   = between_uncoded.pValue(2);

df2_Dir = between_uncoded.DF(3);

% Partial eta squared
if ismember('SumSq', between_uncoded.Properties.VariableNames)
    SS_Dir = between_uncoded.SumSq(2);
    SS_Err = between_uncoded.SumSq(3);

    eta2_Dir = SS_Dir / (SS_Dir + SS_Err);
else
    eta2_Dir = (F_Dir * df1_Dir) / ...
               (F_Dir * df1_Dir + df2_Dir);
end


%% ----------------------------------------------------------
% 6. Print all three ANOVA effects
% ----------------------------------------------------------

fprintf('\n==============================================\n');
fprintf('MIXED ANOVA RESULTS: UNCODED CENTROID VALUES\n');
fprintf('==============================================\n');

fprintf('\nMAIN EFFECT: AFTEREFFECT\n');
fprintf('F(%g, %g) = %.4f, p = %.6g, partial eta squared = %.4f\n', ...
    df1_AE,df2_AE,F_AE,p_AE,eta2_AE);

fprintf('\nMAIN EFFECT: DIRECTION\n');
fprintf('F(%g, %g) = %.4f, p = %.6g, partial eta squared = %.4f\n', ...
    df1_Dir,df2_Dir,F_Dir,p_Dir,eta2_Dir);

fprintf('\nINTERACTION: AFTEREFFECT x DIRECTION\n');
fprintf('F(%g, %g) = %.4f, p = %.6g, partial eta squared = %.4f\n', ...
    df1_Int,df2_Int,F_Int,p_Int,eta2_Int);

fprintf('\n==============================================\n');

%% ----------------------------------------------------------
% 7. Bonferroni post-hoc comparisons
%
% Four simple-effect comparisons:
% 1. Left adaptation:  Baseline vs Adapted (paired t-test)
% 2. Right adaptation: Baseline vs Adapted (paired t-test)
% 3. Baseline: Left vs Right adaptation (independent t-test)
% 4. Adapted:  Left vs Right adaptation (independent t-test)
%
% Bonferroni correction: adjusted p = min(raw p x 4, 1)
% Corrected alpha = .05 / 4 = .0125
% ----------------------------------------------------------

% Left adaptation: Baseline vs Adapted
[~,p1,~,stats1] = ttest( ...
    baselineUncoded(idxLeft), ...
    adaptedUncoded(idxLeft));

% Right adaptation: Baseline vs Adapted
[~,p2,~,stats2] = ttest( ...
    baselineUncoded(idxRight), ...
    adaptedUncoded(idxRight));

% Baseline: Left vs Right adaptation
[~,p3,~,stats3] = ttest2( ...
    baselineUncoded(idxLeft), ...
    baselineUncoded(idxRight), ...
    'Vartype','unequal');

% Adapted: Left vs Right adaptation
[~,p4,~,stats4] = ttest2( ...
    adaptedUncoded(idxLeft), ...
    adaptedUncoded(idxRight), ...
    'Vartype','unequal');

% Raw p-values
pRaw = [p1;p2;p3;p4];

% Bonferroni-adjusted p-values
pBonf = min(pRaw * 4,1);

comparisonNames = {
    'Left: Baseline vs Adapted'
    'Right: Baseline vs Adapted'
    'Baseline: Left vs Right'
    'Adapted: Left vs Right'
    };

tValues = [
    stats1.tstat
    stats2.tstat
    stats3.tstat
    stats4.tstat
    ];

dfValues = [
    stats1.df
    stats2.df
    stats3.df
    stats4.df
    ];

postHocResults = table( ...
    comparisonNames, ...
    tValues, ...
    dfValues, ...
    pRaw, ...
    pBonf, ...
    pBonf < 0.05, ...
    'VariableNames',{ ...
    'Comparison','tStatistic','DF','Raw_p', ...
    'Bonferroni_p','Significant'});

fprintf('\n==============================================\n');
fprintf('BONFERRONI POST-HOC COMPARISONS\n');
fprintf('==============================================\n');
fprintf('Number of comparisons = 4\n');
fprintf('Bonferroni-adjusted alpha = %.4f\n\n',0.05/4);

disp(postHocResults);

%% ----------------------------------------------------------
% 8. Descriptive statistics for each cell
% ----------------------------------------------------------

cellNames = {
    'Left - Baseline'
    'Left - Adapted'
    'Right - Baseline'
    'Right - Adapted'
    };

cellData = {
    baselineUncoded(idxLeft)
    adaptedUncoded(idxLeft)
    baselineUncoded(idxRight)
    adaptedUncoded(idxRight)
    };

nCell = zeros(4,1);
meanCell = nan(4,1);
sdCell = nan(4,1);

for k = 1:4
    nCell(k) = numel(cellData{k});
    meanCell(k) = mean(cellData{k},'omitnan');
    sdCell(k) = std(cellData{k},0,'omitnan');
end

descriptiveResults = table( ...
    cellNames,nCell,meanCell,sdCell, ...
    'VariableNames',{'Condition','N','Mean','SD'});

fprintf('\n==============================================\n');
fprintf('CELL DESCRIPTIVE STATISTICS\n');
fprintf('==============================================\n');
disp(descriptiveResults);

%% ==========================================================
% Interaction Plot: Baseline vs Adapted by Direction
% ORIGINAL centroid values — NO RECODING
% Font: Arial, maximum size 14
% ==========================================================

% Extract original centroid values
baseline = centroidAll(1,:)';
adapted  = centroidAll(2,:)';
direction = condition_map(:);

% Keep participants with valid baseline, adapted, and direction data
valid = isfinite(baseline) & isfinite(adapted) & ...
        isfinite(direction) & ismember(direction,[1 2]);

baseline = baseline(valid);
adapted  = adapted(valid);
direction = direction(valid);

% Separate adaptation directions
idxLeft  = direction == 1;
idxRight = direction == 2;

% Calculate means
meanBaselineLeft  = mean(baseline(idxLeft));
meanAdaptedLeft   = mean(adapted(idxLeft));

meanBaselineRight = mean(baseline(idxRight));
meanAdaptedRight  = mean(adapted(idxRight));

% Calculate standard errors of the mean (SEM)
sem = @(x) std(x,0) / sqrt(numel(x));

semBaselineLeft  = sem(baseline(idxLeft));
semAdaptedLeft   = sem(adapted(idxLeft));

semBaselineRight = sem(baseline(idxRight));
semAdaptedRight  = sem(adapted(idxRight));

% Prepare plot values
x = [1 2];

yLeft = [meanBaselineLeft meanAdaptedLeft];
eLeft = [semBaselineLeft semAdaptedLeft];

yRight = [meanBaselineRight meanAdaptedRight];
eRight = [semBaselineRight semAdaptedRight];

% Plot
figure('Color','w');
hold on;

hLeft = errorbar(x, yLeft, eLeft, '-o', ...
    'LineWidth', 2, ...
    'MarkerSize', 8, ...
    'CapSize', 10);

hRight = errorbar(x, yRight, eRight, '-s', ...
    'LineWidth', 2, ...
    'MarkerSize', 8, ...
    'CapSize', 10);

% Axis formatting
xlim([0.8 2.2]);
xticks([1 2]);
xticklabels({'Baseline','Adapted'});

xlabel('Condition','FontName','Arial','FontSize',14);
ylabel('Centroid Position (mm)','FontName','Arial','FontSize',14);

title('Interaction Between Adaptation Direction and Condition', ...
    'FontName','Arial','FontSize',14,'FontWeight','normal');

legend([hLeft hRight], ...
    {'Leftward Adaptation','Rightward Adaptation'}, ...
    'Location','best','FontName','Arial','FontSize',12);

set(gca, ...
    'FontName','Arial', ...
    'FontSize',14, ...
    'LineWidth',1, ...
    'Box','off');

grid off;
hold off;

% Display sample sizes
fprintf('\nSample sizes:\n');
fprintf('Leftward adaptation:  n = %d\n', sum(idxLeft));
fprintf('Rightward adaptation: n = %d\n', sum(idxRight));



%% ==========================================================
% Eye Contact Distribution (ECD)
% Compare mean eye-contact proportions across left and right eyes
%
% Left ECD  = greater mean proportion on left side
% Right ECD = greater mean proportion on right side
% ==========================================================

% Landmark indices
leftLandmarks  = [3 4 5];  % Left Lateral, Left Pupil, Left Medial
rightLandmarks = [7 8 9];  % Right Medial, Right Pupil, Right Lateral

% Preallocate
leftEyeMean  = nan(numParts,2);
rightEyeMean = nan(numParts,2);

ECD_label = repmat({''},numParts,2);

% ----------------------------------------------------------
% Calculate mean proportions for each participant
% ----------------------------------------------------------

for p = 1:numParts

    for t = 1:2

        % Extract the three left and right landmark proportions
        leftValues = propEyeContactAll(leftLandmarks,t,p);
        rightValues = propEyeContactAll(rightLandmarks,t,p);

        % Average the three proportions on each side
        leftEyeMean(p,t) = mean(leftValues);
        rightEyeMean(p,t) = mean(rightValues);

        % Classify participant's eye contact distribution
        if leftEyeMean(p,t) > rightEyeMean(p,t)

            ECD_label{p,t} = 'Left ECD';

        elseif rightEyeMean(p,t) > leftEyeMean(p,t)

            ECD_label{p,t} = 'Right ECD';

        else

            ECD_label{p,t} = 'Equal';

        end

    end
end


%% ==========================================================
% Participant-level ECD results
% ==========================================================

% Adaptation condition labels
conditionLabel = cell(numParts,1);

for p = 1:numParts

    if condition_map(p) == 1

        conditionLabel{p} = 'Adapt Left';

    elseif condition_map(p) == 2

        conditionLabel{p} = 'Adapt Right';

    else

        conditionLabel{p} = 'Unknown';

    end

end

% Create participant-level results table

ECD_results = table( ...
    subject_map', ...
    conditionLabel, ...
    leftEyeMean(:,1), ...
    rightEyeMean(:,1), ...
    ECD_label(:,1), ...
    leftEyeMean(:,2), ...
    rightEyeMean(:,2), ...
    ECD_label(:,2), ...
    'VariableNames',{ ...
    'Participant', ...
    'AdaptationCondition', ...
    'Baseline_LeftMean', ...
    'Baseline_RightMean', ...
    'Baseline_ECD', ...
    'Adapted_LeftMean', ...
    'Adapted_RightMean', ...
    'Adapted_ECD'});

disp(' ');
disp('==============================================');
disp('PARTICIPANT-LEVEL EYE CONTACT DISTRIBUTION');
disp('==============================================');

disp(ECD_results);


%% ==========================================================
% Count Left ECD and Right ECD by Adaptation Condition
% Separately for Baseline and Adapted
% ==========================================================

fprintf('\n==============================================\n');
fprintf('ECD COUNTS BY ADAPTATION CONDITION\n');
fprintf('==============================================\n');

for t = 1:2

    if t == 1
        timeLabel = 'BASELINE';
    else
        timeLabel = 'ADAPTED';
    end

    fprintf('\n%s\n',timeLabel);
    fprintf('----------------------------------------------\n');

    for d = 1:2

        if d == 1
            directionLabel = 'Adapt Left';
        else
            directionLabel = 'Adapt Right';
        end

        % Select participants in this adaptation condition
        idxCondition = condition_map == d;

        % Count ECD classifications
        nLeftECD = sum(idxCondition' & ...
            strcmp(ECD_label(:,t),'Left ECD'));

        nRightECD = sum(idxCondition' & ...
            strcmp(ECD_label(:,t),'Right ECD'));

        nEqual = sum(idxCondition' & ...
            strcmp(ECD_label(:,t),'Equal'));

        nTotal = sum(idxCondition);

        fprintf('\n%s:\n',directionLabel);
        fprintf('Left ECD  = %d\n',nLeftECD);
        fprintf('Right ECD = %d\n',nRightECD);
        fprintf('Equal     = %d\n',nEqual);
        fprintf('Total     = %d\n',nTotal);

    end
end
