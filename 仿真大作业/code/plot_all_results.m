clear; clc; close all;

% 查找所有 result_*.mat
result_files = dir('result_*.mat');
if isempty(result_files)
    error('未找到任何 result_*.mat 文件，请先运行 run_one_case.m');
end

res_map = containers.Map();
for i = 1:length(result_files)
    load(result_files(i).name);
    res_map(res.cfg.name) = res;
end

% ====================== Figure 3 (带 ±2SE 误差棒) ======================
figure('Position',[100 100 1200 500], 'Color','white');

sys_list = {'H2','E2'};
n_for_fig3 = 10;   % 论文 Figure 3 主要展示 n=10

for i = 1:2
    sys_str = sys_list{i};
    name = sprintf('Case2_%s_pwl_n%d', sys_str, n_for_fig3);
    
    subplot(1,2,i);
    if isKey(res_map, name)
        res = res_map(name);
        tau = res.tau0_vec;
        
        % 计算 averaged kNN + SE（论文公式）
        V_bar = mean(res.v_knn_all, 1);           
        SE    = std(res.v_knn_all, 0, 1) / sqrt(size(res.v_knn_all,1));
        
        % 绘图（严格对齐论文颜色、线型、误差棒）
        plot(tau, res.v_true, 'k-', 'LineWidth', 2.5); hold on;
        plot(tau, V_bar, 'b--', 'LineWidth', 2);
        errorbar(tau, V_bar, 2*SE, 'b', 'LineStyle','none', ...
                 'Marker','o', 'MarkerSize',4, 'CapSize',4, 'LineWidth',1.2);
        
        xlabel('\tau_0', 'FontSize',11);
        ylabel('Virtual waiting time', 'FontSize',11);
        legend({'True v(\tau_0)', 'kNN (\bar V_R)', '±2SE'}, ...
               'Location','best', 'FontSize',10);
        title(sprintf('%s(t)/M/1/50   (n=%d)', sys_str, n_for_fig3), ...
              'FontSize',12, 'FontWeight','bold');
        grid on; box on;
    else
        text(0.5,0.5,'缺少数据', 'HorizontalAlignment','center');
    end
end
sgtitle('Figure 3: Comparison Between \bar{V}_R(\tau_0) ± 2SE and true v(\tau_0)', ...
        'FontSize',13, 'FontWeight','bold');
saveas(gcf, 'Fig3.png');
fprintf('✅ Figure 3 已生成 (带 ±2SE 误差棒) → Fig3.png\n');

% ====================== Figure 4 (H2) 和 Figure 5 (E2) ======================
sys_names = {'H2','E2'};
n_vals = [10 100];

for sys_idx = 1:2
    sys_str = sys_names{sys_idx};
    fig = figure('Position',[100 100 1400 900], 'Color','white');
    
    for row = 1:2   % 上行 n=10，下行 n=100
        n_val = n_vals(row);
        
        name = sprintf('Case2_%s_pwl_n%d', sys_str, n_val);
        if ~isKey(res_map, name), continue; end
        res = res_map(name);
        tau = res.tau0_vec;
        
        % good/bad 挑选（基于平均 EMSE）
        mse_per_rep = mean(res.emse_knn_all, 2);
        [~, good_idx] = min(mse_per_rep);
        [~, bad_idx]  = max(mse_per_rep);
        
        % 左子图：good case
        subplot(2,2,(row-1)*2+1);
        plot(tau, res.v_true, 'k-', 'LineWidth',2.5); hold on;
        plot(tau, res.v_knn_all(good_idx,:), 'b--', 'LineWidth',1.8);
        errorbar(tau, res.v_knn_all(good_idx,:), ...
                 2*sqrt(res.var_sample_all(good_idx,:)), 'r', ...
                 'LineWidth',1.1, 'CapSize',3);
        errorbar(tau, res.v_knn_all(good_idx,:), ...
                 2*sqrt(res.var_boot_all(good_idx,:)), 'g', ...
                 'LineWidth',1.1, 'CapSize',3);
        xlabel('\tau_0'); ylabel('Virtual waiting time');
        legend({'True', 'kNN estimate', 'Sample var (±2σ)', 'Bootstrap var (±2σ)'}, ...
               'Location','best', 'FontSize',9);
        title(sprintf('%s system, n=%d (good case)', sys_str, n_val), ...
              'FontSize',11, 'FontWeight','bold');
        grid on; box on;
        
        % 右子图：bad case
        subplot(2,2,(row-1)*2+2);
        plot(tau, res.v_true, 'k-', 'LineWidth',2.5); hold on;
        plot(tau, res.v_knn_all(bad_idx,:), 'b--', 'LineWidth',1.8);
        errorbar(tau, res.v_knn_all(bad_idx,:), ...
                 2*sqrt(res.var_sample_all(bad_idx,:)), 'r', ...
                 'LineWidth',1.1, 'CapSize',3);
        errorbar(tau, res.v_knn_all(bad_idx,:), ...
                 2*sqrt(res.var_boot_all(bad_idx,:)), 'g', ...
                 'LineWidth',1.1, 'CapSize',3);
        xlabel('\tau_0'); ylabel('Virtual waiting time');
        legend({'True', 'kNN estimate', 'Sample var (±2σ)', 'Bootstrap var (±2σ)'}, ...
               'Location','best', 'FontSize',9);
        title(sprintf('%s system, n=%d (bad case)', sys_str, n_val), ...
              'FontSize',11, 'FontWeight','bold');
        grid on; box on;
    end
    
    sgtitle(sprintf('Figure %d: Performance of kNN Estimator and Two Variance Estimators for %s(t)/M/1/c', ...
                    3+sys_idx, sys_str), 'FontSize',13, 'FontWeight','bold');
    saveas(fig, sprintf('Fig%d_%s.png', 3+sys_idx, sys_str));
    fprintf('✅ Figure %d (%s) 已生成 → Fig%d_%s.png\n', 3+sys_idx, sys_str, 3+sys_idx, sys_str);
end

% ====================== Table 2 & Table 3 ======================
fprintf('\n=== Table 2: k* for different n (mean ± std) ===\n');
n_list = [10 25 50 100];
for sys = {'H2','E2'}
    fprintf('%s:\n', sys{1});
    for n_val = n_list
        name = sprintf('Case2_%s_pwl_n%d', sys{1}, n_val);
        if isKey(res_map, name)
            k_mean = res_map(name).k_star_knn_mean;
            k_std  = res_map(name).k_star_knn_std;
            fprintf('  n=%3d → k* = %3.0f (±%.0f)\n', n_val, k_mean, k_std);
        end
    end
end

fprintf('\n=== Table 3: √EMSE at each τ₀ (kNN vs k-of-1nn) ===\n');
selected = {'Case2_H2_pwl_n10','Case2_H2_pwl_n100', ...
            'Case2_E2_pwl_n10','Case2_E2_pwl_n100'};

for s = selected
    name = s{1};
    if isKey(res_map, name)
        res = res_map(name);
        fprintf('\n%s:\n', name);
        fprintf('τ₀\tkNN √EMSE\tk-of-1nn √EMSE\n');
        for i = 1:length(res.tau0_vec)
            emse_knn  = mean(res.emse_knn_all(:,i));   % 平均 EMSE
            emse_k1nn = mean(res.emse_k1nn_all(:,i));
            fprintf('%2d\t%.4f\t\t%.4f\n', res.tau0_vec(i), ...
                    sqrt(emse_knn), sqrt(emse_k1nn));
        end
    end
end

% ====================== 新增：绘制 √EMSE 对比图（四个子图） ======================
% 四个案例：H2_n10, H2_n100, E2_n10, E2_n100
cases_to_plot = {
    'Case2_H2_pwl_n10',  'H2, n=10';
    'Case2_H2_pwl_n100', 'H2, n=100';
    'Case2_E2_pwl_n10',  'E2, n=10';
    'Case2_E2_pwl_n100', 'E2, n=100'
};

figure('Position',[100 100 1200 800], 'Color','white');
for idx = 1:4
    name = cases_to_plot{idx,1};
    title_str = cases_to_plot{idx,2};
    
    if ~isKey(res_map, name)
        fprintf('警告：缺少 %s 数据，跳过该子图\n', name);
        continue;
    end
    res = res_map(name);
    tau = res.tau0_vec;
    
    % 计算 √EMSE（均值）
    sqrt_emse_knn  = sqrt(res.emse_knn_mean);   % 1×n_tau
    sqrt_emse_k1nn = sqrt(res.emse_k1nn_mean);
    
    subplot(2,2,idx);
    plot(tau, sqrt_emse_knn, 'b-o', 'LineWidth', 1.5, 'MarkerSize', 4); hold on;
    plot(tau, sqrt_emse_k1nn, 'r-s', 'LineWidth', 1.5, 'MarkerSize', 4);
    xlabel('\tau_0');
    ylabel('\surdEMSE');
    legend('kNN', 'k-of-1NN', 'Location','best');
    title(title_str);
    grid on; box on;
end
sgtitle('Figure: √EMSE Comparison Between kNN and k-of-1NN', 'FontSize', 12, 'FontWeight','bold');
saveas(gcf, 'Fig_EMSE_comparison.png');
fprintf('✅ √EMSE 对比图已生成 → Fig_EMSE_comparison.png\n');

fprintf('\n✅ 所有图片生成完毕！\n');