function [route1, route2, benefit1, benefit2, cost1, cost2, payoff1, payoff2, timestamp1, timestamp2] = ctsp6(filename, start_city1, start_city2)
    % Read distance matrix from CSV file
    distance_matrix = csvread(filename);

    % Parameters
    num_cities = size(distance_matrix, 1);
    travel_speed = 50; % km/h
    travel_cost_per_km = 0.2;

    % Initialize variables
    visited = zeros(1, num_cities);
    route1 = start_city1;
    route2 = start_city2;
    visited(start_city1) = 1;
    visited(start_city2) = 1;
    
    % Initialize timestamps for each agent
    timestamp1 = zeros(1, num_cities);
    timestamp2 = zeros(1, num_cities);
    current_time1 = 0;
    current_time2 = 0;

    % Main loop until all cities are visited by at least one agent
    while sum(visited) < num_cities
        % Choose next city using firefly algorithm for Agent 1
        next_city1 = chooseNextCity(route1, route2, visited, distance_matrix, travel_speed);

        % Choose next city using firefly algorithm for Agent 2
        next_city2 = chooseNextCity(route2, route1, visited, distance_matrix, travel_speed);

        % Calculate timestamps for each agent
        if ~visited(next_city1)
            distance1 = distance_matrix(route1(end), next_city1);
            time1 = distance1 / travel_speed; % hours
            current_time1 = current_time1 + time1 ; % Convert hours to milliseconds
            timestamp1(next_city1) = current_time1;  % Update timestamp for Agent 1
        end

        if ~visited(next_city2)
            distance2 = distance_matrix(route2(end), next_city2);
            time2 = distance2 / travel_speed; % hours
            current_time2 = current_time2 + time2 ; % Convert hours to milliseconds
            timestamp2(next_city2) = current_time2;  % Update timestamp for Agent 2
        end

        % Update routes and visited cities
        if ~visited(next_city1)
            route1 = [route1, next_city1];
            visited(next_city1) = 1;
        end
        if ~visited(next_city2)
            route2 = [route2, next_city2];
            visited(next_city2) = 1;
        end
    end
    
    % Append the starting city to the end of each route
    route1 = [route1, start_city1];
    route2 = [route2, start_city2];

    % Calculate benefits, costs, and payoffs for Agent 1
    [benefit1, cost1] = calculateMetrics(route1, distance_matrix, travel_cost_per_km, timestamp1, timestamp2);

    % Calculate benefits, costs, and payoffs for Agent 2
    [benefit2, cost2] = calculateMetrics(route2, distance_matrix, travel_cost_per_km, timestamp1, timestamp2);

    total_benefit = benefit1 + benefit2;
    total_cost = cost1 + cost2;

    payoff1 = calculate_payoff(route1, distance_matrix, num_cities, benefit1, cost1);
    payoff2 = calculate_payoff(route2, distance_matrix, num_cities, benefit2, cost2);
end

function next_city = chooseNextCity(current_route, competitor_route, visited, distance_matrix, speed)
    num_cities = size(distance_matrix, 1);
    distances = zeros(1, num_cities);
    attractiveness = zeros(1, num_cities);

    % Define the weights for cost and payoff
    cost_weight = 0.5; % Adjust this according to preference
    payoff_weight = 1 - cost_weight;

    for city = 1:num_cities
        if ~visited(city) && ~ismember(city, current_route)
            distances(city) = distance_matrix(current_route(end), city);
            % Calculate attractiveness based on distance and benefit
            attractiveness(city) = calculateAttractiveness(distances(city));
            % Calculate cost and payoff for the next city
            [cost, payoff] = calculateCostAndPayoff(current_route, city, distance_matrix);
            % Combine cost and payoff using the objective function
            attractiveness(city) = attractiveness(city) + fun([cost, payoff]);
        else
            distances(city) = Inf;
        end
    end

    % Update attractiveness based on competitor's route
    for i = 1:length(competitor_route)
        competitor_city = competitor_route(i);
        if ~visited(competitor_city)
            competitor_distance = distance_matrix(competitor_route(end), competitor_city);
            attractiveness(competitor_city) = attractiveness(competitor_city) + calculateAttractiveness(competitor_distance);
        end
    end

    % Choose the city with maximum attractiveness
    [~, next_city] = max(attractiveness);
end

function [cost, payoff] = calculateCostAndPayoff(route, next_city, distance_matrix)
    num_cities = length(route);
    total_distance = 0;
    total_cost = 0;
    benefit = 150; % Initialize benefit to 0

    % Iterate over each city in the route
    for i = 1:num_cities - 1
        city1 = route(i);
        city2 = route(i + 1);
        distance = distance_matrix(city1, city2);
        total_distance = total_distance + distance;
        total_cost = total_cost + distance;
        % Add benefit only for non-starting cities
        if i ~= 1 % Exclude starting city
            benefit = benefit + 150;
        end
    end
    
    % Calculate cost for the next city
    cost = total_cost + distance_matrix(route(end), next_city);
    
    % Calculate payoff for the next city
    payoff = benefit - cost;
end


% Phase 2 : Defining objective function
function out = fun(X)
    x1 = X(:,1);
    x2 = X(:,2);
    
    out = x1.^2 - x1.*x2 + x2.^2 + 2.*x1 + 4.*x2 + 3;
    
end

function attractiveness = calculateAttractiveness(distance)
    % Calculate attractiveness as a function of distance
    attractiveness = 1 / distance;
end

function [benefit, cost] = calculateMetrics(route, distance_matrix, travel_cost_per_km, timestamp1, timestamp2)
    num_cities = length(route);
    total_distance = 0;
    benefit = 150; % Initialize benefit to 0

    % Initialize timestamp
    timestamp = 0;

    % Iterate over each city in the route
    for i = 1:num_cities - 1
        city1 = route(i);
        city2 = route(i + 1);
        distance = distance_matrix(city1, city2);
        
        % Calculate time and update timestamp
        time = distance / 50; % hours
        time_ms = time * 3600 * 1000; % Convert hours to milliseconds
        timestamp = timestamp + time_ms;
        
        % Check if the city has been visited by another agent
        if timestamp == 0 || timestamp ~= timestamp1(city2) % Assuming timestamp1 and timestamp2 are available
            % Add benefit only for non-visited cities
            if i ~= 1 % Exclude starting city
                benefit = benefit + 150;
            end
        else
            % Both agents reached the city at the same time, divide benefit equally
            benefit = benefit + 75;
        end
        
        total_distance = total_distance + distance;
    end
    
    % Return to the starting city
    total_distance = total_distance + distance_matrix(route(end), route(1));
    cost = total_distance * travel_cost_per_km;
end


function payoff = calculate_payoff(route, distance_matrix, num_cities, tben, tcos)
    payoff = tben - tcos;
end