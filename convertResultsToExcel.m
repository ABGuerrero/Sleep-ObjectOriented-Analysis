function convertResultsToExcel(matFilePath)
    % If matFilePath is not provided, open a GUI to select the file
    if nargin < 1 || isempty(matFilePath)
        [fileName, filePath] = uigetfile('*.mat', 'Select the .mat file');
        if fileName == 0
            error('No file selected. Exiting function.');
        end
        matFilePath = fullfile(filePath, fileName);
    end
    
    % Generate the Excel file path
    [filePath, fileName, ~] = fileparts(matFilePath);
    excelFilePath = strcat(filePath,'\', fileName, '.xlsx');
    
    % Check if the .mat file exists
    if ~isfile(matFilePath)
        error('The specified .mat file does not exist.');
    end
    
    % Load the all_results.mat file
    data = load(matFilePath);
    allResults = data.allResults;
    
    % Get all the field names (dates)
    dateFields = fieldnames(allResults);
    
    % Initialize a cell array to store the data
    allData = {};
    
    % Iterate over each date field
    for i = 1:numel(dateFields)
        date = dateFields{i};
        resultStruct = allResults.(date);
        
        % Get all subfield names for the current date
        try
            subfields = fieldnames(resultStruct);
        catch 
            continue
        end
        subfields = subfields(3:end);
        % Extract subfield values
        subfieldValues = struct2cell(resultStruct)';
        subfieldValues = subfieldValues(3:end);
        
        % Create a cell array row with the date and subfield values
        row = subfieldValues;
        
        % Append the row to the allData cell array
        if isempty(allData)
            allData = row;
        else
            allData = [allData; row];
        end
    end
    
    % Create a table from the cell array
    varNames = subfields';
    allDataTable = cell2table(allData, 'VariableNames', varNames);
    
    % Write the table to an Excel file
    writetable(allDataTable, excelFilePath);
    
    fprintf('Data successfully written to %s\n', excelFilePath);
end
