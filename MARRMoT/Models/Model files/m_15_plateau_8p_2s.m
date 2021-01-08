classdef m_15_plateau_8p_2s < MARRMoT_model
    % Class for plateau model
    properties
        % in case the model has any specific properties (eg derived theta,
        % add it here)
    end
    methods
        
        % this function runs once as soon as the model object is created
        % and sets all the static properties of the model
        function obj = m_15_plateau_8p_2s(delta_t, theta)
            obj.numStores = 2;                                             % number of model stores
            obj.numFluxes = 9;                                             % number of model fluxes
            obj.numParams = 8; 

            obj.JacobPattern  = [1,1;
                                 1,1];                                     % Jacobian matrix of model store ODEs
                             
            obj.parRanges = [0   , 200;    % Fmax, maximum infiltration rate [mm/d]
                             0   , 5;      % Dp, interception capacity [mm]
                             1   , 2000;   % SUmax, soil misture depth [mm]
                             0.05,    0.95;% Swp, wilting point as fraction of Sumax [-]
                             0   , 1;      % p, coefficient for moisture constrained evaporation [-]
                             1   , 120;    % tp, time delay for routing [d]
                             0   , 4;      % c, capillary rise [mm/d]
                             0   , 1];     % kp, base flow time parameter [d-1]
            
            obj.StoreNames = ["S1" "S2"];                                  % Names for the stores
            obj.FluxNames  = ["pe", "ei", "pie", "pi",...
                              "et", "r",  "c",   "qpgw", "qpieo"];         % Names for the fluxes
            
            obj.Flux_Ea_idx = [2 5];                                       % Index or indices of fluxes to add to Actual ET
            obj.Flux_Q_idx  = [8 9];                                       % Index or indices of fluxes to add to Streamflow
            
            % setting delta_t and theta triggers the function obj.init()
            if nargin > 0 && ~isempty(delta_t)
                obj.delta_t = delta_t;
            end
            if nargin > 1 && ~isempty(theta)
                obj.theta = theta;
            end
        end
        
        % INIT is run automatically as soon as both theta and delta_t are
        % set (it is therefore ran only once at the beginning of the run. 
        % Use it to initialise all the model parameters (in case there are
        % derived parameters) and unit hydrographs and set minima and
        % maxima for stores based on parameters.
        function obj = init(obj)
            % parameters
            theta   = obj.theta;
            delta_t = obj.delta_t;
            tp    = theta(6);     % Time delay of surface flow [d]
            
            % min and max of stores
            obj.store_min = zeros(1,obj.numStores);
            obj.store_max = inf(1,obj.numStores);
            
            % initialise the unit hydrographs and still-to-flow vectors            
            uh = uh_3_half(tp,delta_t);
            
            obj.uhs        = {uh};
            obj.fluxes_stf = arrayfun(@(n) zeros(1, n), cellfun(@length, obj.uhs), 'UniformOutput', false);
        end
        
        % MODEL_FUN are the model governing equations in state-space formulation
        function [dS, fluxes] = model_fun(obj, S)
            % parameters
            theta = obj.theta;
            fmax  = theta(1);     % Maximum infiltration rate [mm/d]
            dp    = theta(2);     % Daily interception [mm]
            sumax = theta(3);     % Maximum soil moisture storage [mm]
            lp    = theta(4);     % Wilting point [-], defined as lp*sumax 
            p     = theta(5);     % Parameter for moisture constrained evaporation [-]
            tp    = theta(6);     % Time delay of surface flow [d]
            c     = theta(7);     % Rate of capillary rise [mm/d]
            kp    = theta(8);     % Groundwater runoff coefficient [d-1]
            
            % delta_t
            delta_t = obj.delta_t;
            
            % unit hydrographs and still-to-flow vectors
            uhs = obj.uhs; stf = obj.fluxes_stf;
            uh = uhs{1}; stf = stf{1};
            
            % stores
            S1 = S(1);
            S2 = S(2);
            
            % climate input
            climate_in = obj.input_climate;
            P  = climate_in(1);
            Ep = climate_in(2);
            T  = climate_in(3);
            
            % fluxes functions
            flux_pe    = interception_2(P,dp);
            flux_ei    = P - flux_pe;                                      % track 'intercepted' water
            flux_pi    = infiltration_4(flux_pe,fmax);
            flux_pie   = flux_pe - flux_pi;
            flux_et    = evap_4(Ep,p,S1,lp,sumax,delta_t);
            flux_c     = capillary_2(c,S2,delta_t);
            flux_r     = saturation_1((flux_pi+flux_c),S1,sumax);
            flux_qpgw  = baseflow_1(kp,S2);
            flux_qpieo = uh(1) * (flux_pie) + stf(1);

            % stores ODEs
            dS1 = flux_pi + flux_c - flux_et - flux_r;
            dS2 = flux_r - flux_c - flux_qpgw;
            
            % outputs
            dS = [dS1 dS2];
            fluxes = [flux_pe, flux_ei, flux_pie, flux_pi,...
                      flux_et, flux_r,  flux_c,   flux_qpgw, flux_qpieo];
        end
        
        % STEP runs at the end of every timestep, use it to update
        % still-to-flow vectors from unit hydrographs
        function step(obj, fluxes)
            % unit hydrographs and still-to-flow vectors
            uhs = obj.uhs; stf = obj.fluxes_stf;
            uh = uhs{1}; stf = stf{1};
            
            % input fluxes to the unit hydrographs 
            flux_pie = fluxes(3);
            
            % update still-to-flow vectors using fluxes at current step and
            % unit hydrographs
            stf      = (uh .* (flux_pie)) + stf;
            stf      = circshift(stf,-1);
            stf(end) = 0;
            
            obj.fluxes_stf = {stf};
        end
    end
end