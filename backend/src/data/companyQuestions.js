// Company-wise questions data for Placement Hub
// Expand this with more problems per company

const COMPANY_QUESTIONS = {
  Google: [
    { id: 'g1', name: 'Two Sum', difficulty: 'easy', topic: 'Arrays', link: 'https://leetcode.com/problems/two-sum/', platform: 'LeetCode' },
    { id: 'g2', name: 'Trapping Rain Water', difficulty: 'hard', topic: 'Arrays', link: 'https://leetcode.com/problems/trapping-rain-water/', platform: 'LeetCode' },
    { id: 'g3', name: 'Word Break', difficulty: 'medium', topic: 'Dynamic Programming', link: 'https://leetcode.com/problems/word-break/', platform: 'LeetCode' },
    { id: 'g4', name: 'LRU Cache', difficulty: 'medium', topic: 'Design', link: 'https://leetcode.com/problems/lru-cache/', platform: 'LeetCode' },
    { id: 'g5', name: 'Serialize and Deserialize Binary Tree', difficulty: 'hard', topic: 'Trees', link: 'https://leetcode.com/problems/serialize-and-deserialize-binary-tree/', platform: 'LeetCode' },
    { id: 'g6', name: 'Word Ladder', difficulty: 'hard', topic: 'Graphs', link: 'https://leetcode.com/problems/word-ladder/', platform: 'LeetCode' },
    { id: 'g7', name: 'Merge K Sorted Lists', difficulty: 'hard', topic: 'Linked List', link: 'https://leetcode.com/problems/merge-k-sorted-lists/', platform: 'LeetCode' },
    { id: 'g8', name: 'Minimum Window Substring', difficulty: 'hard', topic: 'Sliding Window', link: 'https://leetcode.com/problems/minimum-window-substring/', platform: 'LeetCode' },
    { id: 'g9', name: 'Number of Islands', difficulty: 'medium', topic: 'Graphs', link: 'https://leetcode.com/problems/number-of-islands/', platform: 'LeetCode' },
    { id: 'g10', name: 'Longest Palindromic Substring', difficulty: 'medium', topic: 'Strings', link: 'https://leetcode.com/problems/longest-palindromic-substring/', platform: 'LeetCode' },
  ],
  Amazon: [
    { id: 'a1', name: 'Two Sum', difficulty: 'easy', topic: 'Arrays', link: 'https://leetcode.com/problems/two-sum/', platform: 'LeetCode' },
    { id: 'a2', name: 'Best Time to Buy and Sell Stock', difficulty: 'easy', topic: 'Arrays', link: 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/', platform: 'LeetCode' },
    { id: 'a3', name: 'Longest Common Subsequence', difficulty: 'medium', topic: 'Dynamic Programming', link: 'https://leetcode.com/problems/longest-common-subsequence/', platform: 'LeetCode' },
    { id: 'a4', name: 'Merge Intervals', difficulty: 'medium', topic: 'Arrays', link: 'https://leetcode.com/problems/merge-intervals/', platform: 'LeetCode' },
    { id: 'a5', name: 'Clone Graph', difficulty: 'medium', topic: 'Graphs', link: 'https://leetcode.com/problems/clone-graph/', platform: 'LeetCode' },
    { id: 'a6', name: 'Top K Frequent Elements', difficulty: 'medium', topic: 'Heap/Priority Queue', link: 'https://leetcode.com/problems/top-k-frequent-elements/', platform: 'LeetCode' },
    { id: 'a7', name: 'Course Schedule', difficulty: 'medium', topic: 'Graphs', link: 'https://leetcode.com/problems/course-schedule/', platform: 'LeetCode' },
    { id: 'a8', name: 'Design Add and Search Words Data Structure', difficulty: 'medium', topic: 'Tries', link: 'https://leetcode.com/problems/design-add-and-search-words-data-structure/', platform: 'LeetCode' },
    { id: 'a9', name: 'Kth Largest Element in an Array', difficulty: 'medium', topic: 'Heap/Priority Queue', link: 'https://leetcode.com/problems/kth-largest-element-in-an-array/', platform: 'LeetCode' },
    { id: 'a10', name: 'Trapping Rain Water', difficulty: 'hard', topic: 'Arrays', link: 'https://leetcode.com/problems/trapping-rain-water/', platform: 'LeetCode' },
  ],
  Microsoft: [
    { id: 'm1', name: 'Reverse Linked List', difficulty: 'easy', topic: 'Linked List', link: 'https://leetcode.com/problems/reverse-linked-list/', platform: 'LeetCode' },
    { id: 'm2', name: 'Binary Tree Level Order Traversal', difficulty: 'medium', topic: 'Trees', link: 'https://leetcode.com/problems/binary-tree-level-order-traversal/', platform: 'LeetCode' },
    { id: 'm3', name: 'Valid Parentheses', difficulty: 'easy', topic: 'Stack', link: 'https://leetcode.com/problems/valid-parentheses/', platform: 'LeetCode' },
    { id: 'm4', name: 'Lowest Common Ancestor of a Binary Tree', difficulty: 'medium', topic: 'Trees', link: 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-tree/', platform: 'LeetCode' },
    { id: 'm5', name: 'Find All Anagrams in a String', difficulty: 'medium', topic: 'Sliding Window', link: 'https://leetcode.com/problems/find-all-anagrams-in-a-string/', platform: 'LeetCode' },
  ],
  Adobe: [
    { id: 'ad1', name: 'Median of Two Sorted Arrays', difficulty: 'hard', topic: 'Binary Search', link: 'https://leetcode.com/problems/median-of-two-sorted-arrays/', platform: 'LeetCode' },
    { id: 'ad2', name: 'Jump Game', difficulty: 'medium', topic: 'Greedy', link: 'https://leetcode.com/problems/jump-game/', platform: 'LeetCode' },
    { id: 'ad3', name: 'Spiral Matrix', difficulty: 'medium', topic: 'Arrays', link: 'https://leetcode.com/problems/spiral-matrix/', platform: 'LeetCode' },
  ],
  Flipkart: [
    { id: 'f1', name: 'Maximum Subarray', difficulty: 'medium', topic: 'Dynamic Programming', link: 'https://leetcode.com/problems/maximum-subarray/', platform: 'LeetCode' },
    { id: 'f2', name: 'Product of Array Except Self', difficulty: 'medium', topic: 'Arrays', link: 'https://leetcode.com/problems/product-of-array-except-self/', platform: 'LeetCode' },
    { id: 'f3', name: 'Rotate Image', difficulty: 'medium', topic: 'Arrays', link: 'https://leetcode.com/problems/rotate-image/', platform: 'LeetCode' },
  ],
  Uber: [
    { id: 'u1', name: 'Surge Pricing (Custom)', difficulty: 'medium', topic: 'Design', link: 'https://leetcode.com/problems/lru-cache/', platform: 'LeetCode' },
    { id: 'u2', name: 'Find Median from Data Stream', difficulty: 'hard', topic: 'Heap/Priority Queue', link: 'https://leetcode.com/problems/find-median-from-data-stream/', platform: 'LeetCode' },
  ],
  Meta: [
    { id: 'fb1', name: 'Subsets', difficulty: 'medium', topic: 'Backtracking', link: 'https://leetcode.com/problems/subsets/', platform: 'LeetCode' },
    { id: 'fb2', name: 'Regular Expression Matching', difficulty: 'hard', topic: 'Dynamic Programming', link: 'https://leetcode.com/problems/regular-expression-matching/', platform: 'LeetCode' },
    { id: 'fb3', name: 'Alien Dictionary', difficulty: 'hard', topic: 'Graphs', link: 'https://leetcode.com/problems/alien-dictionary/', platform: 'LeetCode' },
  ],
};

module.exports = COMPANY_QUESTIONS;
