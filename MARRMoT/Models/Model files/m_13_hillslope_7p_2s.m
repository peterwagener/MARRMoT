classdef m_13_hillslope_7p_2s < MARRMoT_model
    % Class for hillslope model
    properties
        % in case the model has any specific properties (eg derived theta,
        % add it here)
    end
    methods
        
        % this function runs once as soon as the model object is created
        % and sets all the static properties of the model
        function obj = m_13_hillslope_7p_2s()
            obj.numStores = 2;                                             % number of model stores
            obj.numFluxes = 10;                                            % number of model fluxes
            obj.numParams = 7;
            
            obj.JacobPattern  = [1 1;...
                                 1 1];                                     % Jacobian matrix of model store ODEs
                             
            obj.parRanges = [0   , 5;      % Dw, interception capacity [mm]
                             0   , 10;     % Betaw, soil misture distribution parameter [-]
                             1   , 2000;   % Swmax, soil misture depth [mm]
                             0   , 1;      % a, surface/groundwater division [-]
                             1   , 120;    % th, time delay for routing [d]
                             0   , 4;      % c, capillary rise [mm/d]
                             0   , 1];     % kw, base flow time parameter [d-1]
            
            obj.StoreNames = ["S1" "S2"];                                  % Names for the stores
            obj.FluxNames  = ["pe",   "ei", "ea",    "qse",  "qses",...
                              "qseg", "c",  "qhsrf", "qhgw", "qt"];        % Names for the fluxes
            
            obj.FluxGroups.Ea = [2 3];                                     % Index or indices of fluxes to add to Actual ET
            obj.FluxGroups.Q  = 10;                                        % Index or indices of fluxes to add to Streamflow
            
        end
        
        % INITialisation function
        function obj = init(obj)
            % parameters
            theta   = obj.theta;
            delta_t = obj.delta_t;
            th    = theta(5);     % Routing delay [d]
            
            % initialise the unit hydrographs and still-to-flow vectors            
            uh = uh_3_half(th,delta_t);
            
            obj.uhs        = {uh};
            obj.fluxes_stf = arrayfun(@(n) zeros(1, n), cellfun(@length, obj.uhs), 'UniformOutput', false);
        end
        
        % MODEL_FUN are the model governing equations in state-space formulation        
        function [dS, fluxes] = model_fun(obj, S)
            % parameters
            theta   = obj.theta;
            dw    = theta(1);     % Daily interception [mm]
            betaw = theta(2);     % Soil moisture storage distribution parameter [-]
            swmax = theta(3);     % Maximum soil moisture storage [mm]
            a     = theta(4);     % Division parameter for surface and groundwater flow [-]
            c     = theta(6);     % Rate of capillary rise [mm/d]
            kh    = theta(7);     % Groundwater runoff coefficient [d-1]
            
            % delta_t
            delta_t = obj.delta_t;
            
            % unit hydrographs and still-to-flow vectors
            uhs = obj.uhs; stf = obj.fluxes_stf;
            uh = uhs{1}; stf = stf{1};
            
            % stores
            S1 = S(1);
            S2 = S(2);
            
            % climate input
            t = obj.t;                             % this time step
            climate_in = obj.input_climate(t,:);   % climate at this step
            P  = climate_in(1);
            Ep = climate_in(2);
            T  = climate_in(3);
            
            % fluxes functions
            flux_pe    = interception_2(P,dw);
            flux_ei    = P-flux_pe;                                         % tracks 'intercepted' rainfall
            flux_ea    = evap_1(S1,Ep,delta_t);
            flux_qse   = saturation_2(S1,swmax,betaw,flux_pe);
            flux_qses  = split_1(a,flux_qse);
            flux_qseg  = split_1(1-a,flux_qse);
            flux_c     = capillary_2(c,S2,delta_t);
            flux_qhgw  = baseflow_1(kh,S2);
            flux_qhsrf = uh(1) * flux_qses + stf(1);
            flux_qt    = flux_qhsrf + flux_qhgw;
            
            % stores ODEs
            dS1 = flux_pe   + flux_c - flux_ea - flux_qse;
            dS2 = flux_qseg - flux_c - flux_qhgw;
            
            % outputs
            dS = [dS1 dS2];
            fluxes = [flux_pe   flux_ei flux_ea   flux_qse   flux_qses...
                      flux_qseg flux_c  flux_qhgw flux_qhsrf flux_qt];
        end
        
        % STEP runs at the end of every timestep.
        function obj = step(obj)
            % unit hydrographs and still-to-flow vectors
            uhs = obj.uhs; stf = obj.fluxes_stf;
            uh = uhs{1}; stf = stf{1};
            
            % input fluxes to the unit hydrographs 
            fluxes = obj.fluxes(obj.t,:); 
            flux_qses = fluxes(5);
            
            % update still-to-flow vectors using fluxes at current step and
            % unit hydrographs
            stf      = (uh .* (flux_qses)) + stf;
            stf      = circshift(stf,-1);
            stf(end) = 0;
            
            obj.fluxes_stf = {stf};
        end
    end
end