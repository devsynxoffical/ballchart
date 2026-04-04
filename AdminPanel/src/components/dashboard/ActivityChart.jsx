import React from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

const data = [
    { name: 'Mon', players: 400, battles: 240 },
    { name: 'Tue', players: 300, battles: 139 },
    { name: 'Wed', players: 200, battles: 980 },
    { name: 'Thu', players: 278, battles: 390 },
    { name: 'Fri', players: 189, battles: 480 },
    { name: 'Sat', players: 239, battles: 380 },
    { name: 'Sun', players: 349, battles: 430 },
];

const ActivityChart = () => {
    return (
        <div className="h-[300px] w-full mt-4">
            <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={data}>
                    <defs>
                        <linearGradient id="colorPlayers" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="5%" stopColor="#DAA520" stopOpacity={0.3} />
                            <stop offset="95%" stopColor="#DAA520" stopOpacity={0} />
                        </linearGradient>
                        <linearGradient id="colorBattles" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="5%" stopColor="#00BCD4" stopOpacity={0.3} />
                            <stop offset="95%" stopColor="#00BCD4" stopOpacity={0} />
                        </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" vertical={false} />
                    <XAxis dataKey="name" stroke="#A0A0A0" fontSize={12} tickLine={false} axisLine={false} />
                    <YAxis stroke="#A0A0A0" fontSize={12} tickLine={false} axisLine={false} tickFormatter={(value) => `${value}`} />
                    <Tooltip
                        contentStyle={{ backgroundColor: '#1A1C20', border: '1px solid rgba(255,255,255,0.1)', borderRadius: '8px' }}
                        itemStyle={{ color: '#fff' }}
                    />
                    <Area type="monotone" dataKey="players" stroke="#DAA520" strokeWidth={3} fillOpacity={1} fill="url(#colorPlayers)" />
                    <Area type="monotone" dataKey="battles" stroke="#00BCD4" strokeWidth={3} fillOpacity={1} fill="url(#colorBattles)" />
                </AreaChart>
            </ResponsiveContainer>
        </div>
    );
};

export default ActivityChart;
