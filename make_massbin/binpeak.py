
# Library
import numpy as np
import pandas as pd
import pandas_read_xml as pdx
import os
import argparse

# Functions
def divider (mz_sorted, tol=0.002):
    for i, mass in zip(range(len(mz_sorted)), mz_sorted):
        if max(abs(mass - np.mean(mass)) / np.mean(mass)) > tol:
            diff_mz = np.diff(mass)
            idx_at_max = np.where(diff_mz == max(diff_mz))
            idx_at_max = [x[0] for x in idx_at_max][0]
            left_mz = mass[:idx_at_max + 1]
            right_mz = mass[idx_at_max + 1:]
            mz_sorted[i] = left_mz
            mz_sorted = mz_sorted + [right_mz]
    return mz_sorted

def div_loop_runner (mz_sorted, tol=0.002):
    while True:
        binned_mass = divider(mz_sorted, tol)
        if len(mz_sorted) == len(binned_mass):
            break
        else :
            mz_sorted = binned_mass
    return mz_sorted

def binmass_maker (binned_mass):
    bin_mass = []
    for i in range(len(binned_mass)):
        mass = np.mean(binned_mass[i]).round(2)
        bin_mass.append(mass)
    return sorted(bin_mass)


# Class
class mass_list():
    def __init__(self, xml_path):
        self.path = xml_path

    def path_parsor (self):

        for root, dirs, files in os.walk(self.path):
            file_and_path = []
            filenames = [x for x in files if x.endswith('.xml')]
            for file in files:
                file_path = os.path.join(root, file)
                if file_path.endswith('.xml'):
                    file_and_path.append(file_path)

        profile_list = []
        for file, xml in zip(filenames, file_and_path):
            f = pdx.read_xml(xml, ['document', 'PeakInfo'])
            peakdata = f.values[0]

            mz_vector = []
            intensity_vector = []
            snr_vector = []
            for peak in peakdata:
                data = list(peak.values())
                mz_vector.append(float(data[1]))
                intensity_vector.append(float(data[2]))
                snr_vector.append(float(data[3]))
            intensity_vector = np.array(intensity_vector) / np.max(np.array(intensity_vector))
            intensity_vector = intensity_vector.tolist()
            profile = (file, mz_vector, intensity_vector, snr_vector)
            profile_list.append(list(profile))

        self.profile = profile_list
        self.filename = filenames

    def truncator (self, SNR=7, Length=70, ranges=[3000,20000]):
        profile_list = []
        for prof in self.profile:
            if sum(prof[3]) == 0:
                SNR = 0
            idx = np.arange(len(prof[1]))
            idx1 = [i for i in idx if prof[3][i] >= SNR and prof[1][i] >= ranges[0] and prof[1][i] <= ranges[1]]
            if len(idx1) != 0 :
                int_idx1 = [prof[2][i] for i in idx1]
                int_idx1.sort(reverse=True)
                if len(int_idx1) < Length:
                    Length = len(int_idx1)
                intcut = int_idx1[Length - 1]
                idx2 = [i for i in idx if
                        prof[3][i] >= SNR and prof[1][i] >= ranges[0] and prof[1][i] <= ranges[1] and prof[2][
                            i] >= intcut]
                newprof = [prof[0],
                           [prof[1][i] for i in idx2],
                           [prof[2][i] for i in idx2],
                           [prof[3][i] for i in idx2]]
                profile_list.append(newprof)
        self.profile = profile_list
        self.filename = [x[0] for x in profile_list]

    def make_bins (self, tol=0.002):
        m_bundle = [x[1] for x in self.profile]
        masses = []
        for mass in m_bundle:
            masses = masses + mass
        masses.sort()
        sorted_mz = [masses]
        div_mz = div_loop_runner(sorted_mz, tol)
        binned = binmass_maker(div_mz)
        self.binmass = binned

    def make_binmatrix (self, type='intensity'):
        matrix = np.array([])
        for file, masses, intensities, snrs in self.profile:
            bin = np.zeros(len(self.binmass))
            for mz, intn in zip(masses, intensities):
                diff = abs(np.array(self.binmass) - mz)
                if type == 'intensity':
                    bin[np.where(diff == min(diff))] = intn
                elif type == 'mass':
                    bin[np.where(diff == min(diff))] = mz

            matrix = np.append(matrix, bin)
        matrix = matrix.reshape(-1, len(self.binmass))
        self.feature_matrix = matrix


# Run
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="massbin")
    parser.add_argument("--xmlPath", "-p", type=str, default="xml_export", help="Path where xmls stored.")
    parser.add_argument("--tolerance", "-t", type=float, default=0.03, help="Mass bin tolerance.")
    parser.add_argument("--bintype", "-b", type=str, default="intensity", help="Type of value of mass matrix. Values: 'intensity' or 'mass'.")
    args = parser.parse_args()

    os.chdir("..")
    print(args.xmlPath, type(args.xmlPath))
    print(args.tolerance, type(args.tolerance))
    print(args.bintype, type(args.bintype))

    # By xml data
    DB = mass_list(xml_path=args.xmlPath)
    DB.path_parsor()
    DB.make_bins(tol=args.tolerance)
    DB.make_binmatrix(type=args.bintype)

    # Exporting
    df = pd.DataFrame(DB.feature_matrix, columns=DB.binmass, index=DB.filename)
    df.to_csv("mass_features.csv")




