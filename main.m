%シミュレーター本体
clear;
close all;

% Configクラスを初期化
config = Config();

% Simulatorクラスの初期化
simulator = Simulator(config);

% Simulatorクラスを実行
simulator.run();



%関係ない
clear all;
close all;

% Configクラスの変数の作成
file_name = 'config.yaml';
file_dir = strcat(pwd, '\layout\');
Config = config.Config(file_name, file_dir);   %ここまでOK

% Vissimクラスの作成
Vissim = simulator.Vissim(Config);

%シミュレーションを実行する
for sim_count = 1:Config.simulation.count
    if sim_count == 1  % 制御なしで少し動かす時間

        % シミュレーションを止める時間の設定（ブレイクポイント）
        Vissim.break_time = Vissim.break_time + Config.simulation.time_bef_control;
        Vissim.Com.Simulation.set('AttValue','SimBreakAt',break_time); %これで改善？
        
        % シミュレーションを動かす
        Vissim.Com.Simulation.RunContinuous();  %ここまで大丈夫そう　止まらない

        % 信号現示の決定権をCOMに移しておく
        for sig_i = 1:4
            for sig_j = 1:4
                sg(sig_i,sig_j).set('AttValue', 'State', 1);  %赤
            end
        end

    else
    end

    % シミュレーションを0秒からconfig.cycle_sec * config.simulation_step秒まで行う
    for sim_step = 0:(config.simulation_step - 1)
        % 現在のシミュレーション時間の表示
        current_time = v_obj.Simulation.get('AttValue','SimSec');           % 現在のシミュレーション時間を取得
        fprintf('シミュレーション時間 %4d秒　\n',current_time);               % 現在のシミュレーション時間を表示

        % 状態更新
        vissim.update_states();

        % 次のサイクルの信号機の設定を最適化で求める
        sig = [];                                                           % 次のサイクルの信号機情報をまとめた構造体を初期化
        sig = vissim.optimize();                                            % 最適化を実行
        sig.start_time = current_time + 1;                                  % 次のサイクルの開始時間を設定
        sig.end_time = sig.start_time + control_interval;                   % 次のサイクルの終了時間を設定

        % ブレイクポイントを立てて,そこまでシミュレーションを実行
        v_obj.Simulation.set('AttValue','SimBreakAt',control_interval*(sim_step + 1));
        v_obj.Simulation.RunContinuous();
    end

    % 状態更新(計測データ追加のため)
    vissim.update_states();

    % vehicle network performanceの計測を行う
    vissim.measure_VehNetPerf();
    v_obj.Net.VehicleNetworkPerformanceMeasurement.get('AttValue','DelayAvg(Current,Last,All)')

    % resultファイルの書き込み
    vissim.write_result(result_prefix);
end