# RV_simple 当前结构梳理（聚焦 CSR）

## 1. 工程目录

- `rtl/`：核心 RTL 代码，当前 CSR 主链路也在这里
- `rtl/base_comp/`：基础触发器等底层组件
- `sim/`：简单顶层测试
- `vsim/`：更完整的仿真工程、文件列表、RV32I 自检 testbench
- `netlist/`：综合相关输出
- `doc/`：设计/说明文档

## 2. 核心数据通路

当前顶层是 `rtl/top_core.v`，整体是一个单周期风格的数据通路：

1. `inst_mem` 取指
2. `ctrl_unit` 解码
3. `regfile` 读寄存器
4. `exu` 执行
5. `data_mem` 访存
6. `top_core` 内部完成 PC 更新和写回选择

关键模块分工：

- `rtl/top_core.v`
  - 负责模块集成
  - 负责 `pc` 更新
  - 负责 `imm` 扩展
  - 负责 `WB mux`
- `rtl/ctrl_unit.v`
  - 负责 RV32I 指令解码
  - 输出 load/store/branch/jump/CSR 控制信号
- `rtl/exu.v`
  - 挂接 `alu`
  - 完成 branch compare
  - 挂接 `csr_ctrl`
- `rtl/csr_ctrl.v`
  - 根据 CSR 解码结果生成 `csr_wr_en/csr_rd_en/csr_idx/csr_wb_dat`
- `rtl/csr.v`
  - 真正保存 CSR 寄存器内容

## 3. CSR 相关链路

### 3.1 解码入口

`ctrl_unit.v` 已经把 `opcode == 7'b1110011` 识别为 `is_system`，并进一步区分：

- `csrrw`
- `csrrs`
- `csrrc`
- `csrrwi`
- `csrrsi`
- `csrrci`
- `ecall`
- `ebreak`

其中 CSR 类指令被编码进 `csr_dec_bus`，包括：

- CSR 操作类型
- `rs1/zimm`
- CSR 地址 `instr[31:20]`

### 3.2 执行链路

CSR 相关数据流现在是：

`ctrl_unit -> csr_dec_bus -> exu -> csr_ctrl -> csr`

具体含义：

- `top_core` 把 `csr_dec_bus` 送入 `exu`
- `exu` 内部实例化 `csr_ctrl`
- `csr_ctrl` 读取：
  - `csr_dec_bus`
  - `exu_src0`（这里相当于 rs1 数据）
  - `csr_rd_dat`
- `csr_ctrl` 产出：
  - `csr_wr_en`
  - `csr_rd_en`
  - `csr_idx`
  - `csr_wb_dat`
- `csr` 模块根据 `csr_idx` 访问具体寄存器

### 3.3 写回链路

`top_core.v` 的 `res_src` 已经支持 `WB_MUX_CSR`，因此 CSR 指令执行后可以把旧 CSR 值写回 GPR。

这意味着当前 CSR 基本闭环已经形成：

1. 解码 CSR 指令
2. 读 CSR
3. 生成修改后的 CSR 写值
4. 写回 CSR
5. 将旧 CSR 值写回目的寄存器

## 4. 当前已经落地的 CSR

`rtl/csr.v` 里目前实际实现了：

- `mtvec` (`12'h305`)
- `mscratch` (`12'h340`)
- `mepc` (`12'h341`)
- `mcause` (`12'h342`)

另外还定义了 `mstatus` 的只读常量拼接框架，但当前没有完整接入读写 mux，也没有状态寄存。

## 5. CSR 相关仿真

当前 CSR 不是“只接线未验证”，而是已经进入自检 testbench：

- `vsim/tb_rv32i_check.sv`

里面单独有 `test_csr_ops()`，覆盖了：

- `csrrw`
- `csrrs`
- `csrrc`
- `csrrwi`
- `csrrsi`
- `csrrci`

并检查：

- GPR 写回结果
- `mtvec/mscratch/mepc/mcause` 的内部状态

所以从工程结构上看，CSR 已经不再是散落逻辑，而是一个独立子链路。

## 6. 目前 CSR 结构上的几个明显缺口

### 6.1 CSR 只覆盖了基础寄存器

目前主要是最小集合：

- `mtvec`
- `mscratch`
- `mepc`
- `mcause`

还没有形成完整 machine-mode CSR 子系统，例如：

- `mstatus` 未完整实现
- `mie/mip/mtval` 未实现
- `mret` 未接入

### 6.2 异常入口还没闭环

`top_core.v` 已经预留了：

- `trap_cause_en`
- `trap_mepc_en`
- `trap_mscratch_en`

但当前 `csr_inst` 实例化时直接把这些入口绑成了 `0`，所以异常/陷入写 CSR 这条线还没有真正接通。

也就是说：

- CSR 指令读写已基本可用
- 异常自动写 `mepc/mcause` 还没用上

### 6.3 system 指令的语义还没有完全分流

`ctrl_unit.v` 中 `is_system` 会统一参与：

- `reg_write`
- `res_src = WB_MUX_CSR`

这对 CSR 指令是合理的，但对 `ecall/ebreak` 并不完整。当前看起来：

- `ecall/ebreak` 只被“识别出来”
- 还没有 trap 跳转控制
- 也没有异常入口与 `mtvec/mepc/mcause` 打通

### 6.4 CSR 规范细节还比较简化

`csr_ctrl.v` 目前把所有 CSR 类指令都同时视作可读可写。若后续按 RISC-V 规范补齐，还需要进一步区分：

- `csrrw rd=x0` 时是否真的需要读
- `csrrs/csrrc rs1=x0` 时是否需要写
- `csrrsi/csrrci zimm=0` 时是否需要写

当前实现更像“功能优先”的最小版本。

## 7. 现阶段结论

如果只看“结构是否成型”，当前工程已经从“纯 RV32I 基础通路”扩展到了“带独立 CSR 子链路”的阶段：

- 解码已接入
- 执行已接入
- 存储体已接入
- 写回已接入
- 仿真已覆盖基本 CSR 指令

但如果看“CSR/异常子系统是否完整”，还处在第一阶段：

- 更像 CSR 指令功能已通
- 还不是完整 trap/privileged 架构

## 8. 建议的下一步顺序

建议后续按下面顺序补：

1. 修正 `bltu/bgeu` 的无符号比较
2. 在 `top_core.v` 显式声明 `is_system`
3. 把 `ecall/ebreak` 的异常入口真正接到 `csr` 的 `mepc/mcause`
4. 增加 `pc -> mtvec` 的 trap 跳转
5. 补 `mret`
6. 再扩展 `mstatus/mie/mip/mtval`
