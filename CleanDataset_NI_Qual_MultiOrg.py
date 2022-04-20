######################################################################
# Program: CleanDataset_NI_Qual_MultiOrg.py
# Purpose: Clean the dataset and eliminate types of microorganisms with
# observed positive rates at the boundary
# Remark: Supplementary material to paper:
# Optimal spiking experiment for non-inferiority of qualitative
# microbiological methods on accuracy with multiple microorganisms,
# Journal of Statistics in Biopharmaceutical Research, 2021.
######################################################################
import itertools
from pathlib import Path
import pandas as pd

dist_list = ['NORMAL(1.0,0.25)', 'NORMAL(0.5,0.5)', 'BETA(5.0,1.0)', 'BETA(1.0,1.0)']
theta_list = [0.7, 0.8, 0.9, 1]
labda_list = [1.5, 2.0, 2.5, 3.0, 3.5]
m_list = [5, 10, 15]

ROOT_PATH = Path(r"D:/NI")

def main():
    for dist, theta, labda, m in itertools.product(dist_list, theta_list, labda_list, m_list):
        clean_and_store(ROOT_PATH / f"theta={theta}/Dist={dist}/lambda={labda}/m={m}/input.sas7bdat",
                        ROOT_PATH / f"theta={theta}/Dist={dist}/lambda={labda}/m={m}/cleaninput.csv")


def clean_and_store(input_path: Path, save_path: Path) -> None:
    df_input = pd.read_sas(input_path)
    sim_list = df_input['SIM'].unique().tolist()
    organism_list = df_input['ORGANISM'].unique().tolist()

    for sim, organism in itertools.product(sim_list, organism_list):
        df_detailed = df_input[(df_input.SIM == sim) & (df_input.ORGANISM == organism)]
        meanresp = df_detailed['MEANRESP'].tolist()
        if ((meanresp[0] == 0 and meanresp[-1] == 0) or (meanresp[0] == 1 and meanresp[-1] == 1)):
            df_input.drop(df_detailed.index, inplace=True)
    df_input.to_csv(save_path)


if __name__ == '__main__':
    main()

