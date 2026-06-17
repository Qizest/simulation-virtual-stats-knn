function cases = case_parameters()
% 返回所有实验案例的配置结构体数组

% 全局参数（可统一，也可分别定义）
T_end = 16;
tau0_vec = 1:15;

% 定义案例列表（格式同之前，但转为结构体数组）
case_list = {
    'Case1_H2_pwc_mu20',   'H2', 'M', 'pw-c', 20, 1, 300, 0.5, 50;
    'Case1_E2_pwc_mu20',   'E2', 'M', 'pw-c', 20, 1, 300, 0.5, 50;
    'Case2_H2_pwl_n10',    'H2', 'M', 'pw-l', 20, 1, 50, 0.4, 10;
    'Case2_E2_pwl_n10',    'E2', 'M', 'pw-l', 20, 1, 50, 0.4, 10;
    'Case2_H2_pwl_n25',    'H2', 'M', 'pw-l', 20, 1, 50, 0.4, 25;
    'Case2_E2_pwl_n25',    'E2', 'M', 'pw-l', 20, 1, 50, 0.4, 25;
    'Case2_H2_pwl_n50',    'H2', 'M', 'pw-l', 20, 1, 50, 0.4, 50;
    'Case2_E2_pwl_n50',    'E2', 'M', 'pw-l', 20, 1, 50, 0.4, 50;
    'Case2_H2_pwl_n100',   'H2', 'M', 'pw-l', 20, 1, 50, 0.4, 100;
    'Case2_E2_pwl_n100',   'E2', 'M', 'pw-l', 20, 1, 50, 0.4, 100;
    'Case7_E4_pwl_E4',     'E4', 'E4', 'pw-l', 20, 1, 50, 0.4, 10;
};

n_cases = size(case_list,1);
cases = struct();

for i = 1:n_cases
    cases(i).name = case_list{i,1};
    cases(i).arrival_type = case_list{i,2};
    cases(i).service_dist = case_list{i,3};
    cases(i).rate_type = case_list{i,4};
    cases(i).mu = case_list{i,5};
    cases(i).s = case_list{i,6};
    cases(i).c = case_list{i,7};
    cases(i).p = case_list{i,8};
    cases(i).n = case_list{i,9};
    cases(i).T_end = T_end;
    cases(i).tau0_vec = tau0_vec;
end
end