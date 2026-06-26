import { TrendingUp, TrendingDown } from 'lucide-react';

const colorGradients = {
  blue: 'from-blue-500 to-cyan-400',
  cyan: 'from-cyan-400 to-blue-500',
  green: 'from-green-500 to-emerald-400',
  purple: 'from-purple-500 to-pink-400',
  orange: 'from-orange-500 to-red-400',
  red: 'from-red-500 to-pink-400',
};

export default function StatCard({
  title,
  value,
  icon: Icon,
  color = 'blue',
  trend,
  subtitle,
}) {
  const gradient = colorGradients[color] || colorGradients.blue;
  const isPositive = trend && trend > 0;

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow duration-200">
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div>
          <p className="text-gray-500 text-sm font-medium">{title}</p>
          {subtitle && (
            <p className="text-xs text-gray-400 mt-1">{subtitle}</p>
          )}
        </div>

        {/* Icon container */}
        {Icon && (
          <div className={`p-3 bg-gradient-to-br ${gradient} rounded-lg text-white shadow-lg`}>
            <Icon className="w-5 h-5" />
          </div>
        )}
      </div>

      {/* Value */}
      <div className="flex items-baseline gap-2">
        <h3 className="text-3xl font-bold text-slate-900">{value}</h3>

        {/* Trend */}
        {trend !== undefined && (
          <div
            className={`flex items-center gap-1 px-2 py-1 rounded-full text-xs font-semibold ${
              isPositive
                ? 'bg-green-50 text-green-700'
                : 'bg-red-50 text-red-700'
            }`}
          >
            {isPositive ? (
              <TrendingUp className="w-3 h-3" />
            ) : (
              <TrendingDown className="w-3 h-3" />
            )}
            <span>{Math.abs(trend)}%</span>
          </div>
        )}
      </div>
    </div>
  );
}
