function v_true = compute_empirical_true(tau0_vec, mu, c, arrival_type, p, n_large, T_end, rate_type, service_dist)
% 用大量复制平均作为经验真值
    if nargin < 9, service_dist = 'M'; end
    if nargin < 8, rate_type = 'pw-l'; end
    if nargin < 7, T_end = 16; end
    fprintf('计算经验真值 (n_large = %d)...\n', n_large);
    v_sum = zeros(size(tau0_vec));
    count = zeros(size(tau0_vec));
    for r = 1:n_large
        [t_arr, Y_wait] = simulate_one_replication(r, mu, 1, c, arrival_type, p, T_end, rate_type, service_dist);
        for i = 1:length(tau0_vec)
            tau0 = tau0_vec(i);
            [~, idx] = min(abs(t_arr - tau0));
            if abs(t_arr(idx) - tau0) < 0.5
                v_sum(i) = v_sum(i) + Y_wait(idx);
                count(i) = count(i) + 1;
            end
        end
        if mod(r, 500) == 0
            fprintf('  已完成 %d / %d\n', r, n_large);
        end
    end
    v_true = v_sum ./ count;
    fprintf('✅ 经验真值计算完成！\n');
end