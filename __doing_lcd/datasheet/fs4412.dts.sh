files="skeleton.dtsi exynos4.dtsi exynos4x12-pinctrl.dtsi exynos4x12.dtsi exynos4412.dtsi exynos4412-fs4412.dts"

NOW_DIR=`pwd`
OUT_DTS_FILE=${NOW_DIR}/fs4412.dts

cd arch/arm/boot/dts

> ${OUT_DTS_FILE}
for file in ${files}
do
	echo "copying ${file} ......"

	echo "/* dtsi: ${file} */" >> ${OUT_DTS_FILE}
	cat ${file} >> ${OUT_DTS_FILE}
	echo "/* over here */" >> ${OUT_DTS_FILE}
done
cd ${NOW_DIR}
