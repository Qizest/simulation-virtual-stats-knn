function [t_arr, Y_wait] = simulate_one_replication(repl_id, mu, s, c, arrival_type, p, T_end, rate_type, service_dist)
% 单次复制仿真（支持 pw-l 和 pw-c）
% 修改：在生成到达时传入 T_end，防止超时死循环

    rng(100 + repl_id);
    t_arr = [];
    Y_wait = [];
    t = 0;
    servers = zeros(1, s);
    queue = [];
    waiting_start = [];

    % 根据 rate_type 选择基础到达率函数（用于 E4 或其它）
    if strcmp(rate_type, 'pw-l')
        base_rate = @pw_linear_lambda;
    else
        base_rate = @pw_constant_lambda;
    end

    params = struct('p', p);
    
    % ==================== 根据到达类型定义率函数 ====================
    if strcmp(arrival_type, 'H2')
        if strcmp(rate_type, 'pw-l')
            params.lambda1 = @lambda_H1_linear;
            params.lambda2 = @lambda_H2_linear;
        else % pw-c
            params.lambda1 = @lambda_H1_const;
            params.lambda2 = @lambda_H2_const;
        end
        
    elseif strcmp(arrival_type, 'E2')
        if strcmp(rate_type, 'pw-l')
            params.rate = @(tt) p * lambda_H1_linear(tt) + (1-p) * lambda_H2_linear(tt);
        else % pw-c
            params.rate = @(tt) p * lambda_H1_const(tt) + (1-p) * lambda_H2_const(tt);
        end
        
    elseif strcmp(arrival_type, 'E4')
        params.rate = @(tt) base_rate(tt);
    else
        error('未知到达类型');
    end

    generating_arrivals = true;

    while true
        % 生成下一个到达时间（传入 T_end）
        if generating_arrivals && t < T_end
            [t_next, ~] = generate_nonstationary_arrivals(t, arrival_type, params, 1, rate_type, T_end);
        else
            t_next = inf;
        end

        % 下一个服务完成时间
        t_next_serv = min(servers(servers > 0));
        if isempty(t_next_serv)
            t_next_serv = inf;
        end

        t_next = min(t_next, t_next_serv);
        if isinf(t_next)
            break;  % 无事件
        end

        t = t_next;

        % 处理服务完成
        completed = servers <= t;
        for i = find(completed)'
            if ~isempty(queue)
                arr_t = queue(1); queue(1) = [];
                wait = t - waiting_start(1); waiting_start(1) = [];
                Y_wait(end+1) = wait;
                servers(i) = t + generate_service_time(mu, service_dist);
            else
                servers(i) = 0;
            end
        end

        % 处理新到达
        if t == t_next && t <= T_end
            n_busy = nnz(servers > 0);
            if n_busy + length(queue) < c
                t_arr(end+1) = t;
                if n_busy < s
                    Y_wait(end+1) = 0;
                    free_idx = find(servers == 0, 1);
                    servers(free_idx) = t + generate_service_time(mu, service_dist);
                else
                    queue(end+1) = t;
                    waiting_start(end+1) = t;
                end
            end
        elseif t > T_end
            generating_arrivals = false;
        end
    end
    assert(length(t_arr) == length(Y_wait), '长度不匹配');
end

function st = generate_service_time(mu, service_dist)
    if strcmp(service_dist, 'M')
        st = exprnd(1/mu);
    elseif strcmp(service_dist, 'E4')
        st = sum(exprnd(1/(4*mu), 4, 1));
    else
        error('未知服务分布');
    end
end

% ==================== pw-l 模式下的分支率函数（分段线性） ====================
function lam = lambda_H1_linear(t)
    if t <= 6
        lam = 1 + (30-1)*(t/6);
    elseif t <= 12
        lam = 30;
    else
        lam = 30 - (30-1)*((t-12)/4);
    end
end

function lam = lambda_H2_linear(t)
    if t <= 6
        lam = 1 + (25-1)*(t/6);
    elseif t <= 13
        lam = 25;
    else
        lam = 25 - (25-1)*((t-12)/4);
    end
end

% ==================== pw-c 模式下的分支率函数（分段常数） ====================
function lam = lambda_H1_const(t)
    if t <= 4
        lam = 5 * 1.5;
    elseif t <= 8
        lam = 15 * 1.5;
    elseif t <= 12
        lam = 10 * 1.5;
    else
        lam = 5 * 1.5;
    end
end

function lam = lambda_H2_const(t)
    if t <= 4
        lam = 5 * 0.8;
    elseif t <= 8
        lam = 15 * 0.8;
    elseif t <= 12
        lam = 10 * 0.8;
    else
        lam = 5 * 0.8;
    end
end

% ==================== 基础到达率函数（用于 E4 或其它） ====================
function lam = pw_linear_lambda(t)
    if t <= 4
        lam = 5 + 5*(t/4);
    elseif t <= 8
        lam = 10 + 5*((t-4)/4);
    elseif t <= 12
        lam = 15 - 5*((t-8)/4);
    else
        lam = 10 - 5*((t-12)/4);
    end
end

function lam = pw_constant_lambda(t)
    if t <= 4
        lam = 5;
    elseif t <= 8
        lam = 15;
    elseif t <= 12
        lam = 10;
    else
        lam = 5;
    end
end