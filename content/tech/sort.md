---
title: "基本排序算法总结"
date: 2020-06-06T15:03:40+08:00
draft: false
# mermaid: true
katex: true
tags:
- go
- 算法
---
## 引言
随着时间的推移已经记不清各种基本排序算法的差别在哪里，实际编程当中甚至分不清自己用了哪种排序。总结备忘一下，用 GO 语言加以实现。

## 时间复杂度和稳定性

- 稳定性指在排序数列中有多个相同的元素，经过排序后相同元素的位置没有发生改变则称为稳定排序算法，否则就是不稳定排序算法。

|排序算法|平均时间复杂度|最好情况|最坏情况|空间复杂度|排序方式|稳定性|
|---|---|---|---|---|---|---|
|冒泡排序|O($n^2$)|O(n)|O($n^2$)|O(1)|in-place|稳定|
|选择排序|O($n^2$)|O($n^2$)|O($n^2$)|O(1)|in-place|不稳定|
|插入排序|O($n^2$)|O(n)|O($n^2$)|O(1)|in-place|稳定|
|希尔排序|O(n log n)|O(n $log^2$ n|O(n $log^2$ n)|O(1)|in-place|不稳定|
|归并排序|O(n log n)|O(n log n)|O(n $log^2$ n)|O(n)|out-place|稳定|
|快速排序|O(n log n)|O(n log n)|$O(n^2)$|O(log n)|in-place|不稳定|
|堆排序|O(n log n)|O(n log n)|O(n log n)|O(1)|in-place|不稳定|
|计数排序|O(n+k)|O(n+k)|O(n+k)|O(k)|out-place|稳定|
|桶排序|O(n+k)|O(n+k)|O($n^2$)|O(n+k)|out-place|稳定|
|基数排序|O(n*k)|O(n*k)|O(n*k)|O(n+k)|out-place|稳定|

### 冒泡排序
重复遍历待排序数列，每次比较两个元素，顺序错误则进行交换，直到没有元素再需要交换。由于越小的数会慢慢“浮”到数列顶端，因此得名。

#### 算法步骤
- 比较相邻的元素。如果第一个比第二个大，就交换他们。
- 每一对相邻元素都做同样的对比交换工作，从开始第一对到结尾最后一对一趟遍历完成后最后一个元素是最大的元素。
- 针对所有的元素重复以上步骤，除了最后一个（优化后不再遍历已经对比过的元素）
- 持续对减少的元素做以上操作，直到没有一对数字需要比较。

![冒泡排序示意](/images/bubbleSort.gif "冒泡排序动图演示")

- 输入反序的时候最慢，但是这种情况下一个循环交换也能完成正序排序。
- 冒泡排序有进一步的优化算法。见以下代码示例。
#### 冒泡排序 GO 实现
```go

// BubbleSort 冒泡排序
func BubbleSort(s []int) {
	l := len(s)
	for i := 0; i < l; i++ {
		for j := 0; j < l-1-i; j++ {
			if s[j] > s[j+1] {
				s[j], s[j+1] = s[j+1], s[j]
			}
		}
	}
	fmt.Println("冒泡排序后：", s)
}

// OpBubbleSort 优化后的冒泡排序
// 在一趟排序中如果没有发生交换说明已经是有序的
// 可以直接停止排序
// 这个优化对性能提升没有太大帮助
func OpBubbleSort(s []int) {
	l := len(s)
	var flag bool
	for i := 0; i < l; i++ {
		flag = false
		for j := i + 1; j < l-i; j++ {
			for j := 0; j < l-1-i; j++ {
				if s[j] > s[j+1] {
					s[j], s[j+1] = s[j+1], s[j]
					flag = true
				}
			}
		}
		// 如果没有发生交换说民已经有序，直接返回
		if !flag {
			break
		}
	}
	fmt.Println("冒泡排序后：", s)
}
```

### 选择排序
一种简单直观的排序算法，时间复杂度都是 $O(n^2)$，唯一的好处是减少额外空间的占用。

#### 算法步骤
- 找到最大（小）元素放在数列起始位置。
- 在未排序序列中找到最大（小）的元素放到已排序序列末尾。
- 重复以上步骤。

![选择排序示意图](/images/selectionSort.gif "选择排序动图演示")

#### 选择排序 GO 实现
```go
// SelectSort 选择排序算法
// 升序排序
// 遍历 每次选择最小的数放在排序位置
func SelectSort(s []int) {
	l := len(s)
	fmt.Println(l, cap(s))
	for i := 0; i <= l; i++ {
		// 寻找[i,l)区间里的最小值,并交换
		for j := i + 1; j < l; j++ {
			if s[j] < s[i] {
				// 交换
				s[i], s[j] = s[j], s[i]
			}
		}
	}
	fmt.Println("选择排序后：", s)
}
```

### 插入排序

跟扑克牌排序一样，从未排序数列中取一个元素，在有序的序列中向后扫描，找到相应的位置并插入。

#### 算法步骤
- 将待排序数列的第一个元素当作一个有序序列，其余看成未排序序列。
- 扫描未排序序列，将扫描到的每个元素插入到有序序列的适当位置，如果相等则放在相等元素后面。

![插入排序示意图](/images/insertionSort.gif "插入排序动图演示")

- 和冒泡排序一样，插入排序也有一种优化算法，叫拆半插入。利用二分查找法的原理，先与以排序数列的(n/2)处元素比较，中间元素比它大则往前继续用折半法比较查找合适的插入位置，否则往后半区查找插入位置。

#### 插入排序 GO 实现

```go
// InsertionSort 插入排序
func InsertionSort(s []int) {
	for i := range s {
		// 已排序末位元素索引
		pk := i - 1
		// 待插入的元素
		cu := s[i]
		// 第一趟排序不会执行这个循环
		// 第二趟开始，从后往前遍历已排序数列与待插入元素比较
		// 如果已排序数列中的数大于待插入数则将其后移一个元素
		// 以为插入数腾出空间
		for pk >= 0 && s[pk] > cu {
			s[pk+1] = s[pk]
			pk--
		}
		// 第一趟循环，将第一个元素当作已排序
        // 第二趟开始，如果没有进入子循环（待插入数大于等于已排序末端元素）
        // 待插入数无需移动
		// 如果进入了子循环则相当于将待插入元素插入到比它大的元素前
		s[pk+1] = cu
	}
	fmt.Println("插入排序后：", s)
}
```

### 希尔排序算法

也叫递减增量排序算法，是插入排序的改进版本，它不是稳定算法。

根据插入排序的以下两个性质提出改进的：
- 插入排序对已有一定排序顺序的数据排序时效率更高，可以达到线性效率。
- 插入算法一般情况下是低效的，因为每次只能将数据移动一位。

基本思想：先将待排序数列分割成若干子序列分别进行直接插入，待到整个序列中的记录基本有序时，再对全体记录进行直接插入排序。

#### 算法步骤
- 选择一个增量序列 $t_1,t_2,t_3...,t_j,t_i,t_k 其中 t_i>t_j,t_k=1$。
- 按照增量个数 k，对序列进行增量排序。
- 每趟排序根据对应的增量 $t_i$，将待排序序列分割成若干长度为 m 的子序列，分别对各表进行直接插入排序，仅增量因子为 1 时，整个序列作为一个表来处理，表长度为整个序列的长度。

![希尔排序示例](/images/shellSort.gif "希尔排序算法动图演示")

#### 希尔排序 GO 实现
```go
func ShellSort(s []int) {
	l := len(s)
	gap := 1
	for gap < gap/3 {
		gap = gap*3 + 1
	}
	for gap > 0 {
		for i := gap; i < l; i++ {
			tmp := s[i]
			j := i - gap
			for j >= 0 && s[j] > tmp {
				s[j+gap] = s[j]
				j = j - gap
			}
			s[j+gap] = tmp
		}
		gap = gap / 3
	}
	fmt.Println("希尔排序后：", s)
}
```

### 归并排序

建立在归并操作上的一种有效算法，是分治法的一个典型应用。

有两种实现：

- 自上而下的递归（所有递归方法都可以用迭代重写，所以就有了第二种方法）。
- 自上而下的迭代。

和选择排序一样，性能不受数据量的影响，但是整体表现比选择排序好。代价是增大了空间复杂度。

#### 算法步骤
- 申请空间，使其大小为两个已经排序序列之和，该空间用来存放合并后的序列。
- 设定两个指针，起始位置分别为两个已经排序的序列的起始位置。
- 比较两个指针所指的元素，将小的元素放入合并空间，移动指针到下一位。
- 重复对比放入合并空间以及移动指针的操作，直到指针到序列尾部。
- 将另一序列剩下的所有元素直接放到合并序列尾部。

![归并排序示意图](/images/mergeSort.gif "归并排序动图演示")

![归并排序示意图](/images/mergeSort2.gif "归并排序更直观的动图演示")

#### 归并算法 GO 实现
```go

// MergeSort 归并排序
func MergeSort(s []int) {
	s = mergeSort(s)
	fmt.Println("归并排序后：", s)
}

// 递归
func mergeSort(s []int) []int {
	l := len(s)
	if l < 2 {
		return s
	}
	mid := l / 2
	left := s[0:mid]
	right := s[mid:]
	return merge(mergeSort(left), mergeSort(right))
}

// 分治与合并
func merge(l []int, r []int) []int {
	var rs []int
	for len(l) != 0 && len(r) != 0 {
		if l[0] <= r[0] {
			rs = append(rs, l[0])
			l = l[1:]
		} else {
			rs = append(rs, r[0])
			r = r[1:]
		}
	}
	for len(l) != 0 {
		rs = append(rs, l[0])
		l = l[1:]
	}
	for len(r) != 0 {
		rs = append(rs, r[0])
		r = r[1:]
	}
	return rs
}
```

### 快速排序

快速排序也是分而治之思想在排序算法上的典型应用，从本质上来看，快速排序可以算是在冒泡排序基础上的递归分治法。

快速排序是处理大量数据最快的排序算法之一，最坏情况下时间复杂度达到 $O(n^2)$ 但是在大多数情况下比平均时间复杂度为 O(n long n) 的排序算法表现的更好。

> 快速排序的最坏运行情况是 O(n²)，比如说顺序数列的快排。但它的平摊期望时间是 O(nlogn)，且 O(nlogn) 记号中隐含的常数因子很小，比复杂度稳定等于 O(n log n) 的归并排序要小很多。所以，对绝大多数顺序性较弱的随机数列而言，快速排序总是优于归并排序。

#### 算法步骤
- 从数列中挑选一个元素，称为基准(pivot)。
- 排列数列，所有比基准值小的摆放在基准前面，大的摆在基准后面，相等的放在任意一边。分区完成后基准处于数列的中间位置。
- 递归地把小于基准值元素的子数列和大于基准值元素的子数列排序。

![快速排序示意图](/images/quickSort.gif "快速排序动图演示")

![快速排序示意图](/images/quickSort2.gif "快速排序另外一种动图演示")

#### 快速排序 GO 实现
```go

// QuickSort 快速排序
func QuickSort(s []int) {
	s = quickSort(s, 0, len(s)-1)
	fmt.Println("快速排序后：", s)
}

// 递归分治
func quickSort(s []int, l, r int) []int {
	if l < r {
		pi := partition(s, l, r)
		quickSort(s, l, pi-1)
		quickSort(s, pi+1, r)
	}
	return s
}

// 分区
func partition(s []int, l, r int) int {
	pivot := l
	index := pivot + 1
	for i := index; i <= r; i++ {
		if s[i] < s[pivot] {
			s[i], s[index] = s[index], s[i]
			index++
		}
	}
	s[pivot], s[index-1] = s[index-1], s[pivot]
	return index - 1
}

```

### 堆排序

堆排序可以说是用堆这种数据结构来排序的选择排序。平均时间复杂度为 O(nlogn)。
分为两种：
- 大项堆，每个节点的值都大于或等于其子节点的值，在堆排序算法中用于升序排序。
- 小项堆，每个节点的值都小于或等于其子节点的值，在堆排序算法中用于降序配排序。

#### 算法步骤
- 将待排序序列构建成一个堆 H[0……n-1]，根据（升序降序需求）选择大顶堆或小顶堆。
- 把堆首（最大值）和堆尾互换。
- 把堆的尺寸缩小 1，并调用 shift_down(0)，目的是把新的数组顶端数据调整到相应位置。
- 重复步骤 2，直到堆的尺寸为 1。

![堆排序示意](/images/heapSort.gif "堆排序动图演示")
![堆排序示意](/images/heapSort2.gif "堆排序另外一种动图演示")

#### 堆排序 GO 实现
```go

// HeapSort 堆排序
func HeapSort(s []int) {
	l := len(s)
	buildMaxHeap(s, l)
	for i := l - 1; i >= 0; i-- {
		s[0], s[i] = s[i], s[0]
		l--
		heapify(s, 0, l)
	}
	fmt.Println("堆排序后：  ", s)
}
func buildMaxHeap(s []int, sl int) {
	for i := sl / 2; i >= 0; i-- {
		heapify(s, i, sl)
	}
}
func heapify(s []int, i, sl int) {
	l := 2*i + 1
	r := 2*i + 2
	largest := i
	if l < sl && s[l] > s[largest] {
		largest = l
	}
	if r < sl && s[r] > s[largest] {
		largest = r
	}
	if largest != i {
		s[i], s[largest] = s[largest], s[i]
		heapify(s, largest, sl)
	}
}
```

### 计数排序
计数排序的和兴在于将输入的数据值转化为键存储再额外开辟的数组空间中。计数排序要求排序数列必须是有固定范围的整数。

#### 算法步骤
- 花O(n)的时间扫描一下整个序列 A，获取最小值 min 和最大值 max。
- 开辟一块新的空间创建新的数组 B，长度为 ( max - min + 1)。
- 数组 B 中 index 的元素记录的值是 A 中某元素出现的次数。
- 最后输出目标整数序列，具体的逻辑是遍历数组 B，输出相应元素以及对应的个数。

![计数排序示意](/images/countingSort.gif "计数排序动图演示")
![计数排序示意](/images/countingSort2.gif "计数排序动另一种图演示")

#### 计数排序 GO 实现
```go
// CountingSort 计数排序
func CountingSort(s []int, maxValue int) {
	bucketLen := maxValue + 1
	bucket := make([]int, bucketLen) // 初始为0的数组

	sortedIndex := 0
	length := len(s)

	for i := 0; i < length; i++ {
		bucket[s[i]]++
	}

	for j := 0; j < bucketLen; j++ {
		for bucket[j] > 0 {
			s[sortedIndex] = j
			sortedIndex++
			bucket[j]--
		}
	}
	fmt.Println("计数排序后：", s)
}

```

### 桶排序

桶排序是计数排序的升级版。它利用了函数的映射关系，高效与否关键在于函数映射关系的确定。为了更加高效需要做到以下两点：
- 在额外空间充足的情况下，尽量增大桶的数量。
- 使用的映射韩式能够将输入的 N 个数据平均分配到 K 个桶中。

选择的比较排序算法对于性能的影响至关重要。

- 最快情况：当输入的数据可以平均分配到每一个桶中的时候最快。
- 最慢情况：当输入的数据被分配到了同一个桶中。
#### 算法步骤
- 设置固定数量的空桶。
- 把数据放到对应的桶中。
- 对每个不为空的桶中数据进行排序。
- 拼接不为空的桶中数据，得到结果。

![桶排序示意](/images/BucketSort.gif "桶排序动图演示")

### 基数排序

非比较型排序整数排序算法，原理是将整数按位数切割成不同的数字，饭后按每个位分别比较。由于整数也可以表达字符串，所以基数排序也不是只能用于整数排序。
基数排序、计数排序和桶排序都利用了桶的概念，但是对桶的使用方法上有明显的差异：
- 基数排序：根据键值的每位数来分配桶。
- 计数排序：每个桶只存储单一键值。
- 桶排序：每个桶存储一定范围的数值。

#### 算法步骤
- 将所有待比较数值（正整数）统一为同样的数位长度，数位较短的数前面补零。
- 从最低位开始，依次进行一次排序。
- 从最低位排序一直到最高位排序完成以后, 数列就变成一个有序序列。

![基数排序示意图](/images/radixSort.gif "基数排序动图演示")
![基数排序示意图](/images/radixSort2.gif "基数排序另外一种动图演示")


## 说明
文中所涉及到的图片资料等源自：
- [《十大经典排序算法》](https://sort.hust.cc/)，[github](https://github.com/hustcc/JS-Sorting-Algorithm)。
- [《5分钟学算法》](https://www.cnblogs.com/fivestudy/p/10212306.html)