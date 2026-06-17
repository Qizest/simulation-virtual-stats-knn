function [t_next, phase] = generate_nonstationary_arrivals(t_current, arrival_type, params, current_phase, rate_type, T_end)
% 生成下一个到达时间（增加 T_end 参数，超时返回 inf）
    % 默认相位（避免未赋值）
    phase = 1;
    
    % 如果当前时间已超过结束时间，直接返回 inf
    if t_current >= T_end
        t_next = inf;
        return;
    end

    t = t_current;
    max_lambda = 50;  % 拒绝采样上限

    if strcmp(arrival_type, 'H2')
        p = params.p;
        lambda1 = params.lambda1(t);
        lambda2 = params.lambda2(t);
        if rand < p
            lam = lambda1;
            phase = 1;
        else
            lam = lambda2;
            phase = 2;
        end
        while true
            t = t + exprnd(1/max_lambda);
            if t > T_end
                t_next = inf;
                return;
            end
            if rand < lam/max_lambda
                t_next = t;
                return;
            end
        end

    elseif strcmp(arrival_type, 'E2')
        lam = params.rate(t);
        % 第一阶段
        while true
            t = t + exprnd(1/max_lambda);
            if t > T_end
                t_next = inf;
                return;
            end
            if rand < lam/max_lambda
                break;
            end
        end
        % 第二阶段
        lam = params.rate(t);
        while true
            t = t + exprnd(1/max_lambda);
            if t > T_end
                t_next = inf;
                return;
            end
            if rand < lam/max_lambda
                t_next = t;
                phase = 1;
                return;
            end
        end

    elseif strcmp(arrival_type, 'E4')
        lam = params.rate(t);
        for stage = 1:4
            while true
                t = t + exprnd(1/max_lambda);
                if t > T_end
                    t_next = inf;
                    return;
                end
                if rand < lam/max_lambda
                    break;
                end
            end
            if stage < 4
                lam = params.rate(t);
            end
        end
        t_next = t;
        phase = 1;
        return;

    else
        error('未知到达类型');
    end
end