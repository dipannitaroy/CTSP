% Set the number of cities
numCities = input('Enter number of cities: ');



% Define the filename
filename = 'sir_dataset.csv';

% Create a cell array to store the details
details = cell(numCities * (numCities - 1), 12); % Preallocate space

% Loop through all combinations of start cities
k = 1;
for i = 1:numCities
    for j = 1:numCities
       if i == j
           continue;
       end
        % Call ctsp6 function for each combination of start cities
        [route1, route2, benefit1, benefit2, cost1, cost2, payoff1, payoff2, timestamp1, timestamp2] = ctsp6(filename, i, j);
        
        % Store the details in the cell array
        details{k, 1} = i;
        details{k, 2} = j;
        details{k, 3} = route1;
        details{k, 4} = route2;
        details{k, 5} = benefit1;
        details{k, 6} = benefit2;
        details{k, 7} = cost1;
        details{k, 8} = cost2;
        details{k, 9} = payoff1;
        details{k, 10} = payoff2;
        details{k, 11} = timestamp1;
        details{k, 12} = timestamp2;
        
        k = k + 1;
    end
end

% Convert the cell array to a table
details_table = cell2table(details, 'VariableNames', {'Start_City_1', 'Start_City_2', 'Route_Agent_1', 'Route_Agent_2', 'Benefit_Agent_1', 'Benefit_Agent_2', 'Cost_Agent_1', 'Cost_Agent_2', 'Payoff_Agent_1', 'Payoff_Agent_2', 'Timestamp_Agent_1', 'Timestamp_Agent_2'});

% Write the table to a CSV file
writetable(details_table, 'sir_result2.csv');
