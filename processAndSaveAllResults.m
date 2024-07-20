function processAndSaveAllResults(baseFolder)
    % If baseFolder is not provided, open a GUI to select the folder
    if nargin < 1 || isempty(baseFolder)
        baseFolder = uigetdir(pwd, 'Select the base folder');
        if baseFolder == 0
            error('No folder selected. Exiting function.');
        end
    end

    % Initialize the final results structure
    allResults = struct();

    % Recursively search and process subfolders
    allResults = processSubfolders(baseFolder, allResults);
    allResults.plotSubfield = @(subfield, plotType, interactivePlot, saveImage) plotSubfield(allResults, subfield, plotType, interactivePlot, saveImage);
    allResults.plotRatio = @(plotType, interactivePlot, saveImage) plotRatio(allResults, plotType, interactivePlot, saveImage);
    allResults.plotCorrelation = @(subfield, lagFlag, session, interactivePlot, saveImage) plotCorrelation(allResults, subfield, lagFlag, session, interactivePlot, saveImage);

    % Save the consolidated results in the base folder
    save(fullfile(baseFolder, 'all_results.mat'), 'allResults');
end

function allResults = processSubfolders(baseFolder, allResults)
    % Get subfolders
    folderContents = dir(baseFolder);
    subfolders = folderContents([folderContents(:).isdir]);
    subfolders = subfolders(~ismember({subfolders(:).name}, {'.', '..'}));

    % Iterate through each subfolder
    for i = 1:numel(subfolders)
        subfolderName = fullfile(subfolders(i).folder, subfolders(i).name);
        results = processSingleSubfolder(subfolderName);
        allResults.(results.date) = results;
    end
end

function results = processSingleSubfolder(folder)
    cd(folder)
% Initialize the data structure
    results = struct();
    results.calculatePercentage = @(a, b) a * 100 / b;
    results.plotData = @plotData;
    
    % Extract date from the current folder name
    [~, folderName] = fileparts(folder);
    dateStr = extractDateFromFolderName(folderName);
    dateStr = replace(dateStr,'-','_');
    dateStr = ['d_', dateStr];
    results.date = dateStr;
    
    % Initialize result fields to NaN
    results = initResultsFields(results);
    
    % Process and load different .mat files and populate the results struct
    results = processMatFiles(results);
    
    % Save the results for the current subfolder
    save(fullfile(folder, 'summarized_results.mat'), 'results');
end

function results = initResultsFields(results)
    % Initialize result fields to NaN
    results.S1_dur = NaN;
    results.S2_dur = NaN;
    results.S3_dur = NaN;

    results.S1_still_dur = NaN;
    results.S1_still_prop = NaN;
    results.S2_still_dur = NaN;
    results.S2_still_prop = NaN;
    results.S3_still_dur = NaN;
    results.S3_still_prop = NaN;

    results.S1_SWS_dur = NaN;
    results.S1_SWS_prop = NaN;
    results.S2_SWS_dur = NaN;
    results.S2_SWS_prop = NaN;
    results.S3_SWS_dur = NaN;
    results.S3_SWS_prop = NaN;

    results.S1_REM_dur = NaN;
    results.S1_REM_prop = NaN;
    results.S2_REM_dur = NaN;
    results.S2_REM_prop = NaN;
    results.S3_REM_dur = NaN;
    results.S3_REM_prop = NaN;

    results.S1_SWS_bouts = NaN;
    results.S2_SWS_bouts = NaN;
    results.S3_SWS_bouts = NaN;

    results.S1_SWR = NaN;
    results.S2_SWR = NaN;
    results.S3_SWR = NaN;

    results.S1_DWT = NaN;
    results.S2_DWT = NaN;
    results.S3_DWT = NaN;

    results.DWT_channel = NaN;

    results.S1_DWTxSWR = NaN;
    results.S2_DWTxSWR = NaN;
    results.S3_DWTxSWR = NaN;
end

function results = processMatFiles(results)
    try
        load('epoch_times.mat', 'epoch_times');
        results.S1_dur = (epoch_times(1,2) - epoch_times(1,1))/60000000;
        results.S2_dur = (epoch_times(3,2) - epoch_times(3,1))/60000000;
        results.S3_dur = (epoch_times(5,2) - epoch_times(5,1))/60000000;
    catch
        % Do nothing, results are already initialized to NaN
    end
    try
        load('sleep_states_lengths.mat', 'sleep1_still', 'sleep2_still', 'sleep3_still', 'sws_duration', 'rem_duration');
        results.S1_still_dur = sleep1_still;
        results.S1_still_prop = results.S1_still_dur / results.S1_dur;

        results.S2_still_dur = sleep2_still;
        results.S2_still_prop = results.S2_still_dur / results.S2_dur;

        results.S3_still_dur = sleep3_still;
        results.S3_still_prop = results.S3_still_dur / results.S3_dur;

        results.S1_SWS_dur = sws_duration{size(sws_duration,2)}(1);
        results.S1_SWS_prop = (results.S1_SWS_dur / 60) / results.S1_still_dur;

        results.S2_SWS_dur = sws_duration{size(sws_duration,2)}(2);
        results.S2_SWS_prop = (results.S2_SWS_dur / 60) / results.S2_still_dur;

        results.S3_SWS_dur = sws_duration{size(sws_duration,2)}(3);
        results.S3_SWS_prop = (results.S3_SWS_dur / 60) / results.S3_still_dur;


        results.S1_REM_dur = rem_duration{size(rem_duration,2)}(1);
        results.S1_REM_prop = (results.S1_REM_dur / 60) / results.S1_still_dur;


        results.S2_REM_dur = rem_duration{size(rem_duration,2)}(2);
        results.S2_REM_prop = (results.S2_REM_dur / 60) / results.S2_still_dur;

        results.S3_REM_dur = rem_duration{size(rem_duration,2)}(3);
        results.S3_REM_prop = (results.S3_REM_dur / 60) / results.S3_still_dur;
    catch 
        % Do nothing, results are already initialized to NaN
    end
    try
        load('sws_lengths.mat', 'sws1_times', 'sws2_times', 'sws3_times');
        results.S1_SWS_bouts = size(sws1_times,1);
        results.S2_SWS_bouts = size(sws2_times,1);
        results.S3_SWS_bouts = size(sws3_times,1);
    catch
        % Do nothing, results are already initialized to NaN
    end
    try
        load('ripples_resample.mat', 'ripples1', 'ripples2', 'ripples3');
        results.S1_SWR = size(ripples1,1);
        results.S2_SWR = size(ripples2,1);
        results.S3_SWR = size(ripples3,1);
    catch
        % Do nothing, results are already initialized to NaN
    end
    try
        load('delta_neg_locs.mat', 'delta_neg_locs');
        maxCount = 0;
        maxCell = {};
        maxCellPosition = [];
        % Iterate through the first-level cells
        for i = 1:length(delta_neg_locs)
            currentCell = delta_neg_locs{i};
            totalRecords = 0;
            % Iterate through the third-level cells and count the records
            for j = 1:length(currentCell)
                totalRecords = totalRecords + numel(currentCell{1,j});
            end
            % Check if the current cell has the maximum number of records
            if totalRecords > maxCount
                maxCount = totalRecords;
                maxCell = currentCell;
                maxCellPosition = i;
            end
        end
        results.S1_DWT = size(maxCell{1},2);
        results.S2_DWT = size(maxCell{2},2);
        results.S3_DWT = size(maxCell{3},2);
        results.DWT_channel = maxCellPosition;
    catch
        % Do nothing, results are already initialized to NaN
    end
    try
        load('DWTxSWR_Peaks.mat', 'S1_peak_SWRxDWT', 'S2_peak_SWRxDWT', 'S3_peak_SWRxDWT');
        results.S1_DWTxSWR = S1_peak_SWRxDWT;
        results.S2_DWTxSWR = S2_peak_SWRxDWT;
        results.S3_DWTxSWR = S3_peak_SWRxDWT;
    catch
        % Do nothing, results are already initialized to NaN
    end
end

function plotData(data, xField, yField)
    % Plot data from the struct
    if isfield(data, xField) && isfield(data, yField)
        figure;
        plot(data.(xField), data.(yField));
        xlabel(xField);
        ylabel(yField);
        title([xField ' vs ' yField]);
    else
        error('Fields %s or %s not found in the data struct.', xField, yField);
    end
end

function dateStr = extractDateFromFolderName(folderName)
    % Extract date from folder name with format '2023-05-26_11-53-37'
    datePattern = '\d{4}-\d{2}-\d{2}';
    dateMatch = regexp(folderName, datePattern, 'match');
    if ~isempty(dateMatch)
        dateStr = dateMatch{1};
    else
        dateStr = 'Unknown';
    end
end

function plotSubfield(allResults, subfield, plotType, interactivePlot, saveImage)
    % PLOTSUBFIELD Plot data from a specific subfield across dates.
    %
    % Inputs:
    %   allResults      - Structure containing all the results data.
    %   subfield        - Subfield within each result structure to plot.
    %   plotType        - Type of plot to generate: 'line' or 'bar'.
    %   interactivePlot - Boolean indicating whether to enable interactive plot features.
    %                     Default is true.
    %   saveImage       - Boolean indicating whether to save the plot as an image.
    %                     Default is true.
    %
    % Press Tab after typing the function name to see this legend.

    % Set default values if not provided
    if nargin < 3
        error('Insufficient input arguments. Specify allResults, subfield, and plotType.');
    end
    if nargin < 4
        interactivePlot = true; % Default to enable interactive plotting
    end
    if nargin < 5
        saveImage = true; % Default to save the plot as an image
    end

    % Get all dates (fields) from allResults
    dates = fieldnames(allResults);
    
    % Initialize arrays for x and y data
    xData = dates;
    yData = zeros(1, numel(dates));
    
    % Collect y data for the specified subfield
    for i = 1:numel(dates)
        if isfield(allResults.(dates{i}), subfield)
            yData(i) = allResults.(dates{i}).(subfield);
        else
            yData(i) = NaN; % Assign NaN if subfield is not present
        end
    end
    
    % Plot the data based on specified plot type
    fig = figure;
    switch lower(plotType)
        case 'line'
            plot(1:numel(xData), yData, '-o');
        case 'bar'
            bar(1:numel(xData), yData);
        otherwise
            error('Invalid plot type. Use "line" or "bar".');
    end

    % Replace underscores with spaces for labels and title
    subfieldLabel = strrep(subfield, '_', ' ');
    xDataLabels = strrep(dates, '_', ' ');
    xDataLabels = strrep(xDataLabels, 'd', '');
    
    % Set plot labels and title
    set(gca, 'XTick', 1:numel(xData), 'XTickLabel', xDataLabels);
    xlabel('Date');
    ylabel(subfieldLabel);
    title(['Plot of ', subfieldLabel, ' across all dates']);
    xtickangle(45); % Rotate x-axis labels for better readability
    
    % Enable interactive plotting features if requested
    if interactivePlot
        zoom on;
        datacursormode on;
        rotate3d on;
    end
    
    % Save plot as an image file if requested
    if saveImage
        % Generate file name based on the plot title
        imageName = ['Plot_', subfieldLabel, '_across_all_dates.png']; % Adjust as needed
        % Save plot in the current directory
        saveas(fig, imageName);
        fprintf('Plot saved as %s\n', imageName);
    end
end



function plotRatio(allResults, plotType, interactivePlot, saveImage)
    % PLOTRATIO Plot ratio between two subfields across dates.
    %
    % Inputs:
    %   allResults      - Structure containing all the results data.
    %   plotType        - Type of plot to generate: 'line' or 'bar'.
    %   interactivePlot - Boolean indicating whether to enable interactive plot features.
    %                     Default is true.
    %   saveImage       - Boolean indicating whether to save the plot as an image.
    %                     Default is true.
    %
    % Press Tab after typing the function name to see this legend.
    
    % Set default values if not provided
    if nargin < 2
        error('Insufficient input arguments. Specify allResults and plotType.');
    end
    if nargin < 3
        interactivePlot = true; % Default to enable interactive plotting
    end
    if nargin < 4
        saveImage = true; % Default to save the plot as an image
    end

    % Get all dates (fields) from allResults
    dates = fieldnames(allResults);
    
    % Initialize arrays for x and y data
    xData = {};
    yData = [];
    
    % Collect y data for the specified subfield
    for i = 1:numel(dates)
        if isstruct(allResults.(dates{i})) && ...
                isfield(allResults.(dates{i}), 'S3_DWTxSWR') && ...
                isfield(allResults.(dates{i}), 'S1_DWTxSWR')
            yData(end+1) = allResults.(dates{i}).S3_DWTxSWR / allResults.(dates{i}).S1_DWTxSWR;
            xData{end+1} = dates{i};
        else
            % Skip if not a struct or if required fields are missing
            continue;
        end
    end
    
    % Convert cell array to string array for xData labels
    xData = string(xData);
    
    % Plot the data based on the specified plot type
    fig = figure;
    switch lower(plotType)
        case 'line'
            plot(1:numel(xData), yData, '-o', 'Color', 'k');
        case 'bar'
            bar(1:numel(xData), yData);
        otherwise
            error('Invalid plot type. Use "line" or "bar".');
    end

    % Replace underscores with spaces for labels and title
    subfieldLabel = 'Ratio Peak Sleep 3 / Sleep 1';
    xDataLabels = strrep(xData, '_', ' ');
    xDataLabels = strrep(xDataLabels, 'd', '');
    
    % Set plot labels and title
    set(gca, 'XTick', 1:numel(xData), 'XTickLabel', xDataLabels);
    xlabel('Date');
    ylabel(subfieldLabel);
    title(['Plot of ', subfieldLabel, ' across all dates']);
    xtickangle(45); % Rotate x-axis labels for better readability
    
    % Enable interactive plotting features if requested
    if interactivePlot
        zoom on;
        datacursormode on;
        rotate3d on;
    end
    
    % Save plot as an image file if requested
    if saveImage
        % Generate file name based on the plot title
        imageName = ['Plot_Ratio_Peak_Sleep_3_Sleep_1.png']; % Adjust as needed
        % Save plot in the current directory
        saveas(fig, imageName);
        fprintf('Plot saved as %s\n', imageName);
    end
end

function plotCorrelation(allResults, subfield, lagFlag, session, interactivePlot, saveImage)
    % PLOTCORRELATION Plot correlation between task performance and a subfield.
    %
    % Inputs:
    %   allResults      - Structure containing all the results data.
    %   subfield        - Subfield within each result structure to correlate with.
    %   lagFlag         - Flag indicating correlation with next day (1) or same day (2).
    %                     Default is 1.
    %   session         - Which session to use: '1' for Task1, '2' for Task2, 'both' for average.
    %                     Default is 'both'.
    %   interactivePlot - Boolean indicating whether to enable interactive plot features.
    %                     Default is true.
    %   saveImage       - Boolean indicating whether to save the plot as an image.
    %                     Default is true.
    %
    % Press Tab after typing the function name to see this legend.

    % Set default values if not provided
    if nargin < 3
        lagFlag = 1; % Default to correlation with next day
    end
    if nargin < 4
        session = 'both'; % Default to using both sessions
    end
    if nargin < 5
        interactivePlot = true; % Default to enable interactive plotting
    end
    if nargin < 6
        saveImage = true; % Default to save the plot as an image
    end

    dates = fieldnames(allResults);
    nDates = numel(dates);
    
    % Initialize arrays for x and y data
    xData = zeros(1, nDates);
    yData = zeros(1, nDates);
    
    % Collect y data for the specified subfield
    for i = 1:nDates
        if isfield(allResults.(dates{i}), subfield)
            yData(i) = allResults.(dates{i}).(subfield);
        else
            yData(i) = NaN; % Assign NaN if subfield is not present
        end
    end
    
    % Collect x data for the task performance
    for i = 1:nDates
        if lagFlag == 1 && i < nDates
            nextDay = dates{i+1};
        else
            nextDay = dates{i};
        end
        
        if isfield(allResults.(nextDay), 'Task1') && isfield(allResults.(nextDay), 'Task2')
            switch session
                case '1'
                    xData(i) = allResults.(nextDay).Task1;
                case '2'
                    xData(i) = allResults.(nextDay).Task2;
                case 'both'
                    xData(i) = mean([allResults.(nextDay).Task1, allResults.(nextDay).Task2]);
                otherwise
                    error('Invalid session. Use "1", "2", or "both".');
            end
        else
            xData(i) = NaN; % Assign NaN if Task1 or Task2 is not present
        end
    end
    
    % Remove NaN values
    validIdx = ~isnan(xData) & ~isnan(yData);
    xData = xData(validIdx);
    yData = yData(validIdx);
    
    % Perform linear regression
    p = polyfit(xData, yData, 1);
    yFit = polyval(p, xData);
    
    % Compute correlation coefficient and p-value
    [R, P] = corr(xData', yData');
    
    % Plot the scatter plot with regression line
    fig = figure;
    scatter(xData, yData, 'filled');
    hold on;
    plot(xData, yFit, 'r-', 'LineWidth', 2);
    hold off;
    
    % Set labels and title
    subfieldLabel = strrep(subfield, '_', ' ');
    xlabel('Task Performance');
    ylabel(subfieldLabel);

    % Determine the lag label
    if lagFlag == 1
        lagLabel = 'Next Day';
    else
        lagLabel = 'Same Day';
    end
    
    title(['Correlation between Task Performance and ', subfieldLabel, ' (', lagLabel, ')']);
    
    % Display R-squared value and p-value on the plot
    text(min(xData), max(yData), sprintf('R^2 = %.2f\np = %.4f', R^2, P), ...
        'VerticalAlignment', 'top', 'HorizontalAlignment', 'left', 'FontSize', 12);
    
    % Enable interactive plotting features if requested
    if interactivePlot
        zoom on;
        datacursormode on;
        rotate3d on;
    end
    
    % Save plot as an image file if requested
    if saveImage
        % Generate file name based on the plot title
        imageName = sprintf('Correlation_%s_%s.png', subfieldLabel, lagLabel);
        % Save plot in the current directory
        saveas(fig, imageName);
        fprintf('Plot saved as %s\n', imageName);
    end
end
