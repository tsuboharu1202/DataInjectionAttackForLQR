classdef SystemData
    properties (SetAccess = private)
        A double = []
        B double = []
        Q double = []
        R double = []
        X double = []
        Z double = []
        U double = []
    end
    
    methods
        function obj = SystemData(A,B,Q,R,X,Z,U)
            arguments
                A double = []
                B double = []
                Q double = []
                R double = []
                X double = []
                Z double = []
                U double = []
            end
            obj.A = A; obj.B = B;
            obj.Q = Q; obj.R = R;
            obj.X = X; obj.Z = Z; obj.U = U;
            obj = obj.validate();   % 生成時チェック
        end
        
        % =======================
        % 不変っぽい更新API
        % =======================
        function newObj = withX(obj, newX)
            newObj = obj;
            newObj.X = newX;
            newObj = newObj.validate();
        end
        
        function newObj = withU(obj, newU)
            newObj = obj;
            newObj.U = newU;
            newObj = newObj.validate();
        end
        
        function newObj = withZ(obj, newZ)
            newObj = obj;
            newObj.Z = newZ;
            newObj = newObj.validate();
        end
        
        function newObj = withXZU(obj, newX, newZ, newU)
            newObj = obj;
            newObj.X = newX;
            newObj.Z = newZ;
            newObj.U = newU;
            newObj = newObj.validate();
        end
        
        function  [L_opt, S_opt, J_opt, diagInfo] = solveSDPBySystem(obj)
            [L_opt, S_opt, J_opt, diagInfo] = sdp.solveSDP(obj.X, obj.U, obj.Z, obj.Q, obj.R);
        end
        
        function K = opt_K(obj)
            [L_opt, ~, ~, ~] = solveSDPBySystem(obj);
            [K,~] = sdp.postprocess_K(obj.U,L_opt,obj.X);
        end
        
        function J_opt = opt_score(obj)
            [~, ~, J_opt, ~] = solveSDPBySystem(obj);
        end
        
        function K_star = calc_K_star(obj)
            [K_star, ~, ~, ~, ~] = attack_helper.closest_destabilizing_update(obj);
        end
        
        function bool_stable_with_K = is_stable_with_K(obj,K)
            spectral = max(abs(eig(obj.A+obj.B*K)));
            bool_stable_with_K = 1;
            if spectral>= 1
                bool_stable_with_K = 0;
            end
        end
        
        
    end
    
    methods (Static)
        function obj = constructFromDimension(n, m, T, x0)
            arguments
                n  (1,1) double {mustBePositive, mustBeInteger}
                m  (1,1) double {mustBePositive, mustBeInteger}
                T  (1,1) double {mustBePositive, mustBeInteger}
                x0 (:,1) double = []
            end
            [A, B, Q, R] = datasim.make_lti(n, m);
            U = utils.make_inputU(m, T);
            if isempty(x0), x0 = zeros(n,1); end
            [X, Z] = datasim.simulate_openloop(A, B, U, x0);
            obj = SystemData(A, B, Q, R, X, Z, U);
        end
    end
    
    methods (Access = private)
        function obj = validate(obj)
            % 正方・対称性
            if ~isempty(obj.A)
                assert(size(obj.A,1)==size(obj.A,2), 'A must be square.');
            end
            if ~isempty(obj.Q)
                assert(size(obj.Q,1)==size(obj.Q,2), 'Q must be square.');
                assert(issymmetric(obj.Q), 'Q must be symmetric.');
            end
            if ~isempty(obj.R)
                assert(size(obj.R,1)==size(obj.R,2), 'R must be square.');
                assert(issymmetric(obj.R), 'R must be symmetric.');
            end
            
            % 次元整合
            if ~isempty(obj.A) && ~isempty(obj.B)
                n = size(obj.A,1);
                assert(size(obj.B,1)==n, 'B rows must match A.');
                if ~isempty(obj.X), assert(size(obj.X,1)==n, 'X rows must match A.'); end
                if ~isempty(obj.Z), assert(size(obj.Z,1)==n, 'Z rows must match A.'); end
                if ~isempty(obj.U), assert(size(obj.U,1)==size(obj.B,2), 'U rows must match input dim.'); end
                
                if ~isempty(obj.X) && ~isempty(obj.U)
                    assert(size(obj.X,2) == size(obj.U,2), 'X cols must match U cols.');
                end
                if ~isempty(obj.Z) && ~isempty(obj.U)
                    assert(size(obj.Z,2) == size(obj.U,2), 'Z cols must match U cols.');
                end
            end
        end
        
    end
end
