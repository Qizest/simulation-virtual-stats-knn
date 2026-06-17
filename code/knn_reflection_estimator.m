function v_hat = knn_reflection_estimator(data, tau0, k, T_end, boundary_thresh)
    % 边界反射法 kNN 估计
    % data: cell array，每个元素为 [t, Y] 矩阵
    % tau0: 目标时间点
    % k: 近邻数
    % T_end: 时间区间终点
    % boundary_thresh: 边界阈值，距离边界小于该值时启用反射
    
    all_t = [];
    all_y = [];
    
    for j = 1:length(data)
        t_j = data{j}(:,1);
        y_j = data{j}(:,2);
        
        % 判断是否在边界区域
        if tau0 <= boundary_thresh
            % 左边界反射：将 t > tau0 的点镜像到左侧
            idx_right = t_j > tau0;
            t_right = t_j(idx_right);
            y_right = y_j(idx_right);
            t_reflected = 2*tau0 - t_right;  % 镜像映射
            all_t = [all_t; t_j; t_reflected];
            all_y = [all_y; y_j; y_right];
            
        elseif tau0 >= T_end - boundary_thresh
            % 右边界反射：将 t < tau0 的点镜像到右侧
            idx_left = t_j < tau0;
            t_left = t_j(idx_left);
            y_left = y_j(idx_left);
            t_reflected = 2*tau0 - t_left;
            all_t = [all_t; t_j; t_reflected];
            all_y = [all_y; y_j; y_left];
            
        else
            % 非边界区域：直接使用原始数据
            all_t = [all_t; t_j];
            all_y = [all_y; y_j];
        end
    end
    
    if isempty(all_t)
        v_hat = NaN;
        return;
    end
    
    % 标准 kNN 估计
    [~, idx] = sort(abs(all_t - tau0));
    k = min(k, length(idx));
    v_hat = mean(all_y(idx(1:k)));
end