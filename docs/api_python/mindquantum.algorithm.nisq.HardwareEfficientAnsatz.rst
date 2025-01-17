.. py:class:: mindquantum.algorithm.nisq.HardwareEfficientAnsatz(n_qubits, single_rot_gate_seq, entangle_gate=X, entangle_mapping='linear', depth=1)

    HardwareEfficientAnsatz是一种可以很容易地在量子芯片上高效实现的ansatz。

    HardwareEfficientAnsatz由一层单比特旋转门和一层纠缠门构成。单比特旋转门层由一个或多个作用于每个量子位的旋转门构造。
    两个量子比特纠缠门层是由CNOT、CZ、XX、YY、ZZ等作用于纠缠映射构建的。了解更多详细信息，请访问https://www.nature.com/articles/nature23879。

    **参数：**

    - **n_qubits** (int) – 此ansatz的比特数。
    - **single_rot_gate_seq** (list[BasicGate]) – 作用于每个量子位的参数化旋转门列表。
    - **entangle_gate** (BasicGate) – 非参数化纠缠门。如果它是单个量子位门，则将使用控制版本。默认值：XGate。
    - **entangle_mapping** (Union[str, list[tuple[int]]]) – 纠缠门的纠缠映射。“线性”表示纠缠门将作用于每个相邻的量子比特。"all"表示纠缠门将作用于任何两个qbuits。此外，可以通过将纠缠映射设置为两个量子位元组的列表来指定要执行纠缠的两个量子位。默认值："线性"。
    - **depth** (int) – ansatz的深度。默认值：1。
