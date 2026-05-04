from pathlib import Path
import sys

sys.path.append("../script/hdlregression")

from hdlregression import HDLRegression


VALID_VARIANTS = ("init", "bfm", "vvc", "vvc_split")


def add_uvvm_common(hr, uvvm_path: Path) -> None:
    hr.add_files(str(uvvm_path / "uvvm_util/src/*.vhd"), "uvvm_util")


def add_uvvm_bfm(hr, uvvm_path: Path) -> None:
    hr.add_files(str(uvvm_path / "bitvis_vip_sbi/src/sbi_bfm_pkg.vhd"), "bitvis_vip_sbi")
    hr.add_files(
        str(uvvm_path / "bitvis_vip_scoreboard/src/*.vhd"),
        "bitvis_vip_scoreboard"
    )


def add_uvvm_vvc(hr, uvvm_path: Path) -> None:
    hr.add_files(
        str(uvvm_path / "uvvm_vvc_framework/src/*.vhd"),
        "uvvm_vvc_framework"
    )

    hr.add_files(str(uvvm_path / "bitvis_vip_sbi/src/*.vhd"), "bitvis_vip_sbi")
    hr.add_files(
        str(uvvm_path / "uvvm_vvc_framework/src_target_dependent/*.vhd"),
        "bitvis_vip_sbi",
    )

    hr.add_files(
        str(uvvm_path / "bitvis_vip_scoreboard/src/*.vhd"),
        "bitvis_vip_scoreboard"
    )

    hr.add_files(
        str(uvvm_path / "bitvis_vip_clock_generator/src/*.vhd"),
        "bitvis_vip_clock_generator",
    )
    hr.add_files(
        str(uvvm_path / "uvvm_vvc_framework/src_target_dependent/*.vhd"),
        "bitvis_vip_clock_generator",
    )


def extract_tb_variant_from_argv() -> str | None:
    """
    Look for a custom --tb <variant> argument and remove it from sys.argv,
    so HDLRegression only sees its own arguments.
    """
    if "--tb" not in sys.argv:
        return None

    idx = sys.argv.index("--tb")

    if idx + 1 >= len(sys.argv):
        raise SystemExit("Missing value after --tb. Valid values: init, bfm, vvc, vvc_split")

    tb_variant = sys.argv[idx + 1].lower()

    if tb_variant not in VALID_VARIANTS:
        raise SystemExit(
            f"Unknown testbench variant '{tb_variant}'. "
            f"Valid options are: {', '.join(VALID_VARIANTS)}"
        )

    # Remove our custom arguments before HDLRegression sees them
    del sys.argv[idx:idx + 2]

    return tb_variant


def select_tb_variant_interactively() -> str:
    print("\nSelect testbench variant:")
    print("  1) init       - dumb testbench with pin wiggle and assert")
    print("  2) bfm        - BFM-based testbench")
    print("  3) vvc        - VVC-based testbench")
    print("  4) vvc_split  - split VVC-based testbench")

    while True:
        choice = input("Enter choice [1-4] (default 3): ").strip()

        if choice == "":
            return "vvc"
        if choice == "1":
            return "init"
        if choice == "2":
            return "bfm"
        if choice == "3":
            return "vvc"
        if choice == "4":
            return "vvc_split"

        print("Invalid choice. Please enter 1, 2, 3, or 4.")


def add_variant_files(hr, tb_variant: str, uvvm_path: Path) -> None:
    add_uvvm_common(hr, uvvm_path)

    if tb_variant == "init":
        hr.set_result_check_string("SIMULATION COMPLETED")
        pass
    elif tb_variant == "bfm":
        add_uvvm_bfm(hr, uvvm_path)
    elif tb_variant in {"vvc", "vvc_split"}:
        add_uvvm_vvc(hr, uvvm_path)
    else:
        raise ValueError(f"Unsupported testbench variant: {tb_variant}")


def main() -> None:
    # 1) Allow explicit custom flag: --tb <variant>
    tb_variant = extract_tb_variant_from_argv()

    # 2) If not given, ask interactively
    if tb_variant is None:
        tb_variant = select_tb_variant_interactively()

    hr = HDLRegression()

    repo_root = Path(__file__).resolve().parent
    uvvm_path = (repo_root / "../tools/uvvm").resolve()
    src_dir = (repo_root / "../src").resolve()
    tb_root = (repo_root / "../tb").resolve()
    tb_dir = (tb_root / tb_variant).resolve()

    add_variant_files(hr, tb_variant, uvvm_path)

    hr.add_files(str(src_dir / "*.vhd"), "design_lib")
    hr.add_files(str(tb_dir / "*.vhd"), "test_lib")

    hr.start()


if __name__ == "__main__":
    main()